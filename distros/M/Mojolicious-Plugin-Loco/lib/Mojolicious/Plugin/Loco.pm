package Mojolicious::Plugin::Loco 0.008;

# ABSTRACT: launch a web browser; easy local GUI

use Mojo::Base 'Mojolicious::Plugin';

use Browser::Open 'open_browser_cmd';
use File::ShareDir 'dist_file';
use Mojo::ByteStream 'b';
use Mojo::Util qw(hmac_sha1_sum steady_time);

sub register {
    my ($self, $app, $o) = @_;
    my $conf = {
        config_key   => 'loco',
        entry        => '/',
        initial_wait => 15,
        final_wait   => 3,
        api_path     => '/hb/',
        %$o,
    };
    if (my $loco = $conf->{config_key}) {
        unless (my $ac = $app->config($loco)) {
            $app->config($loco, $conf);
        }
        else {
            %$ac = (%$conf, %$ac);
            $conf = $ac;
        }
    }

    my $api =
      Mojo::Path->new($conf->{api_path})->leading_slash(1)->trailing_slash(1);
    my ($init_path, $hb_path, $js_path) =
      map { $api->merge($_)->to_string } qw(init hb heartbeat.js);

    $app->helper(
        'loco.config' => sub {
            my $c = shift;

            # Hash
            return $conf unless @_;

            # Get
            return $conf->{ $_[0] } unless @_ > 1 || ref $_[0];

            # Set
            my $values = ref $_[0] ? $_[0] : {@_};
            @{$conf}{ keys %$values } = values %$values;
            return $c;
        }
    );

    $app->helper(
        'loco.reply_400' => sub {
            my $c       = shift;
            my %options = (
                info   => '',
                status => $c->stash('status') // 400,
                (@_ % 2 ? ('message') : (message => 'Bad Request')), @_
            );
            return $c->render(template => 'done', title => 'Error', %options);
        }
    );

    $app->helper(
        'loco.csrf_fail' => sub {
            my $c = shift;
            return 1 if '400' eq ($c->res->code // '');
            return $c->loco->reply_400(info => 'unexpected origin')
              if $c->validation->csrf_protect->error('csrf_token');
        }
    );

    $app->helper(
        'loco.id_fail' => sub {
            my $c = shift;
            return 1 if '400' eq ($c->res->code // '');
            return $c->loco->reply_400(info => 'wrong session')
              unless $c->loco->id;
        }
    );

    $app->helper(
        'loco.quit' => sub {
            my $c = shift;
            return if $c->loco->csrf_fail;
            $c->render(
                template => "done",
                format   => "html",
                title    => "Finished",
                header   => "Close this window"
            ) unless $c->res->code;
            Mojo::IOLoop->timer(1 => sub { shift->stop });
        }
    );

    $app->hook(
        before_server_start => sub {
            my ($server, $app) = @_;
            return if $conf->{browser_launched}++;
            my ($url) = map {
                my $u = Mojo::URL->new($_);
                $u->host($u->host =~ s![*]!localhost!r);
            } @{ $server->listen };

            my $_test = $conf->{_test_browser_launch};

            # no explicit port means this is coming from UserAgent
            return
              unless ($url->port || $_test);

            $conf->{seed} = my $seed =
              _make_csrf($app, $$ . steady_time . rand . 'x');

            $url->path($init_path)->query(s => $seed);

            my $cmd = $conf->{browser} // open_browser_cmd();
            unless ($cmd) {
                die "Cannot find browser to execute"
                  unless defined $cmd;
                return;
            }
            elsif (ref($cmd) eq 'CODE') {
                $cmd->($url);
            }
            else {
                if ($_test) {
                    $_test->($cmd, $url);
                    return;
                }
                if ($^O eq 'MSWin32') {
                    system start => (
                        $cmd =~ m/^microsoft-edge/
                        ? ("microsoft-edge:$url")
                        : (($cmd eq 'start' ? () : ($cmd)), "$url")
                    ) and die "exec '$cmd' failed";
                }
                else {
                    my $pid;
                    unless ($pid = fork) {
                        unless (fork) {
                            exec $cmd, $url->to_string;
                            die "exec '$cmd' failed";
                        }
                        exit 0;
                    }
                    waitpid($pid, 0);
                }
            }
            _reset_timer($conf->{initial_wait});
        }
    );

    $app->hook(
        before_routes => sub {
            my $c = shift;
            $c->validation->csrf_token('')
              if ($conf->{seed} || !$c->session->{'loco.id'});
        }
    ) unless $conf->{allow_other_sessions};

    $app->helper(
        'loco.id' => sub {
            my $c = shift;
            undef $c->session->{csrf_token}
              if @_;
            return $c->session('loco.id', @_);
        }
    );

    $app->routes->get(
        $init_path => sub {
            my $c    = shift;
            my $seed = $c->param('s') // '' =~ s/[^0-9a-f]//gr;

            if (length($seed) >= 40
                && $seed eq ($conf->{seed} // ''))
            {
                delete $conf->{seed};
                $c->loco->id(1);
            }
            $c->redirect_to($conf->{entry});
        }
    );

    $app->routes->get(
        $hb_path => sub {
            my $c = shift;
            state $hcount = 0;
            if ($c->validation->csrf_protect->error('csrf_token')) {

                # print STDERR "bad csrf: "
                # . $c->validation->input->{csrf_token} . " vs "
                # . $c->validation->csrf_token . "\n";
                return $c->render(
                    json    => { error => 'unexpected origin' },
                    status  => 400,
                    message => 'Bad Request',
                    info    => 'unexpected origin'
                );
            }
            _reset_timer($conf->{final_wait});
            $c->render(json => { h => ++$hcount });

            #    return $c->helpers->reply->not_found()
            #      if ($hcount > 5);
        }
    );

    $app->static->extra->{ $js_path =~ s!^/!!r } =
      dist_file(__PACKAGE__ =~ s/::/-/gr, 'heartbeat.js');

    push @{ $app->renderer->classes }, __PACKAGE__;

    $app->helper(
        'loco.jsload' => sub {
            my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
            my ($c, %option) = @_;
            my $csrf   = $c->csrf_token;
            my $jquery = $option{jquery} // '/mojo/jquery/jquery.js';
            b(
                (
                    join "",
                    map { $c->javascript($_) . "\n" }
                      (length($jquery) ? ($jquery) : ()),
                    $js_path
                )
                . $c->javascript(
                    sub {
                        <<END
\$.fn.heartbeat.defaults.ajax.url = '$hb_path';
\$.fn.heartbeat.defaults.ajax.headers['X-CSRF-Token'] = '$csrf';
END
                          . $c->include(
                            'ready',
                            format   => 'js',
                            nofinish => 0,
                            %option, _cb => $cb
                          );
                    }
                )
            );
        }
    );

}

sub _make_csrf {
    my ($app, $seed) = @_;
    hmac_sha1_sum(pack('h*', $seed), $app->secrets->[0]);
}

sub _reset_timer {
    state $timer;
    Mojo::IOLoop->remove($timer)
      if defined $timer;
    return unless my $wait = shift;
    $timer = Mojo::IOLoop->timer(
        $wait,
        sub {
            print STDERR "stopping...";
            shift->stop;
        }
    );
}

1;

__DATA__

@@ layouts/done.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title>
%= stylesheet begin
body { background-color: #ddd; font-family: helvetica; }
h1 { font-size: 40px; color: white }
% end
  </head>
  <body><%= content %></body>
</html>

@@ done.html.ep
% layout 'done';
% title $title;
<h1 id="header"><%= $header %></h1>
<h2><span id="status"></span> <span id="message"></span></h2>
<p id="info"></p>

@@ ready.js.ep
$.ready.then(function() {
    $().heartbeat()
%== $_cb ? $_cb->() : ''
% unless ($nofinish) {
    .on_finish(function(unexpected,o) {
% my ($hd,$bdy) = do {
%   my $d = Mojo::DOM->new($c->render_to_string(template => "done", format => "html", title => "Finished", header => "Close this window"));
%   map {"'" . (Mojo::Util::trim($d->at($_)->content)
%                =~ s/'/\\047/gr =~ s/\n/'\n    +'\\n/gr) . "'"} qw(head body)
% };
      $('head').html(<%== $hd %>);
      $('body').html(<%== $bdy %>);
      if (unexpected) {
        $('#header').html('Error');
        $('#status').html(o.code);
        $('#message').html(o.msg);
        $('#info').html(o.status == 'error' ? '' : "("+o.msg+")");
      }
    })
% }
    .start();
});
