package Mojolicious::Plugin::Loco 0.001;

# ABSTRACT: launch local GUI via default web browser

use Mojo::Base 'Mojolicious::Plugin';

use Browser::Open 'open_browser';
use File::ShareDir 'dist_file';
use Mojo::ByteStream 'b';
use Mojo::Util qw(hmac_sha1_sum steady_time);

sub register {
    my ($self, $app, $o) = @_;
    my %conf = (
        entry        => '/',
        initial_wait => 10,
        final_wait   => 3,
        api_path     => '/hb/',
        %$o
    );
    my $api =
      Mojo::Path->new($conf{api_path})->leading_slash(1)->trailing_slash(1);
    my ($init_path, $hb_path, $js_path) =
      map { $api->merge($_)->to_string } qw(init hb heartbeat.js);

    $app->helper('loco.conf' => sub { \%conf });
    $app->hook(
        before_server_start => sub {
            my ($server, $app) = @_;
            return if $conf{browser_launched};
            ++$conf{browser_launched};
            my ($url) =
              map  { $_->host($_->host =~ s![*]!localhost!r); }
              grep { $_->host =~ m/^(?:[*]|localhost|127[.]([0-9.]+))$/ }
              map  { Mojo::URL->new($_) } @{ $server->listen };
            die "Must be listening at a loopback URI" unless $url;

            # no explicit port means this is coming from UserAgent
            return
              unless ($url->port);

            $conf{seed} = my $seed =
              _make_csrf($app, $$ . steady_time . rand . 'x');

            $url->path($init_path)->query(s => $seed);
            my $e = open_browser($url->to_string);
            if ($e // 1) {
                unless ($e) {
                    die "Cannot find browser to execute";
                }
                else {
                    die "Error executing: "
                      . Browser::Open::open_browser_cmd . "\n";
                }
            }
            _reset_timer($conf{initial_wait});
        }
    );
    $app->routes->get(
        $init_path => sub {
            my $c    = shift;
            my $seed = $c->param('s') // '' =~ s/[^0-9a-f]//gr;

            my $u = Mojo::URL->new($conf{entry});
            if (length($seed) >= 40
                && $seed eq ($conf{seed} // ''))
            {
                delete $conf{seed};

                # make sure we get a fresh one
                undef $c->session->{csrf_token};
                $conf{csrf} = my $csrf = $c->csrf_token;
            }
            $c->redirect_to($u);
        }
    );
    $app->routes->get(
        $hb_path => sub {
            my $c = shift;
            state $hcount = 0;
            if (   $c->validation->csrf_protect->error('csrf_token')
                || $c->csrf_token ne $conf{csrf})
            {
                print STDERR "bad csrf: "
                  . $c->validation->input->{csrf_token} . " vs "
                  . $c->validation->csrf_token . "\n";
                return $c->render(
                    json    => { error => 'unexpected origin' },
                    status  => 400,
                    message => 'Bad Request',
                    info    => 'unexpected origin'
                );
            }
            _reset_timer($conf{final_wait});
            $c->render(json => { h => ++$hcount });

            #    return $c->helpers->reply->not_found()
            #      if ($hcount > 5);
        }
    );

    # $app->hook(
    # 	before_dispatch => sub {
    # 	    my $c = shift;
    # 	    return unless $conf{csrf};
    # 	    $c->reply->bad_request(info => 'unexpected origin')
    # 	      if $c->validation->csrf_protect->error('csrf_token');
    # 	});

    $app->static->extra->{ $js_path =~ s!^/!!r } =
      dist_file(__PACKAGE__ =~ s/::/-/gr, 'heartbeat.js');

    push @{ $app->renderer->classes }, __PACKAGE__;

    $app->helper(
        'loco.jsload' => sub {
            my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
            my ($c, %option) = @_;
            my $csrf = $c->csrf_token;
            b(
                (
                    join "",
                    map { $c->javascript($_) . "\n" }
                      ($option{nojquery} ? () : ('/mojo/jquery/jquery.js')),
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

    # $app->helper(
    # 	'reply.bad_request', sub {
    # 	    my $c = shift;
    # 	    my %options = (info => '', status => $c->stash('status') // 400,
    # 			   (@_%2 ? ('message') : (message => 'Bad Request')), @_);
    # 	    return $c->render(template => 'done', title => 'Error', %options);
    # });
}

sub _make_csrf {
    my ($app, $seed) = @_;
    hmac_sha1_sum(pack('h*', $seed), $app->secrets->[0]);
}

sub _reset_timer {
    state $hb_wait;
    state $timer;
    $hb_wait = shift if @_;
    Mojo::IOLoop->remove($timer)
      if defined $timer;
    $timer = Mojo::IOLoop->timer(
        $hb_wait,
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
