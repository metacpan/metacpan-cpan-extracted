package Mojolicious::Plugin::CGI;
use Mojo::Base 'Mojolicious::Plugin';

use File::Basename;
use File::Spec;
use IO::Pipely 'pipely';
use Mojo::Util qw(b64_decode encode);
use POSIX 'WNOHANG';
use Perl::OSType 'is_os_type';
use Socket qw(AF_INET inet_aton);
use Sys::Hostname;

use constant CHECK_CHILD_INTERVAL => $ENV{CHECK_CHILD_INTERVAL} || 0.01;
use constant DEBUG                => $ENV{MOJO_PLUGIN_CGI_DEBUG};
use constant IS_WINDOWS           => is_os_type('Windows');
use constant READ                 => 0;
use constant WRITE                => 1;

our $VERSION = '0.40';
our %ORIGINAL_ENV = %ENV;

has env => sub { +{%ORIGINAL_ENV} };

sub register {
  my ($self, $app, $args) = @_;
  my $pids = $app->{'mojolicious_plugin_cgi.pids'} ||= {};

  $args = {route => shift @$args, script => shift @$args} if ref $args eq 'ARRAY';
  $args->{env} ||= $self->env;
  $args->{run} = delete $args->{script} if ref $args->{script} eq 'CODE';
  $args->{pids} = $pids;

  $app->helper('cgi.run' => sub { _run($args, @_) }) unless $app->renderer->helpers->{'cgi.run'};
  $app->{'mojolicious_plugin_cgi.tid'}
    ||= Mojo::IOLoop->recurring(CHECK_CHILD_INTERVAL, sub { local ($?, $!); _waitpids($pids); });

  if ($args->{support_semicolon_in_query_string}
    and !$app->{'mojolicious_plugin_cgi.before_dispatch'}++)
  {
    $app->hook(
      before_dispatch => sub {
        $_[0]->stash('cgi.query_string' => $_[0]->req->url->query->to_string);
      }
    );
  }

  return unless $args->{route};    # just register the helper
  die "Neither 'run', nor 'script' is specified." unless $args->{run} or $args->{script};
  $args->{route} = $app->routes->any("$args->{route}/*path_info", {path_info => ''})
    unless ref $args->{route};
  $args->{script} = File::Spec->rel2abs($args->{script}) || $args->{script} if $args->{script};
  $args->{route}->to(cb => sub { _run($args, @_) });
}

sub _child {
  my ($c, $args, $stdin, $stdout, $stderr) = @_;
  my @STDERR = @$stderr ? ('>&', fileno $stderr->[WRITE]) : ('>>', $args->{errlog});

  Mojo::IOLoop->reset;
  warn "[CGI:$args->{name}:$$] <<< (@{[$stdin->slurp]})\n" if DEBUG;
  open STDIN, '<', $stdin->path or die "STDIN @{[$stdin->path]}: $!" if -s $stdin->path;
  open STDERR, $STDERR[0], $STDERR[1] or die "STDERR: @$stderr: $!";
  open STDOUT, '>&', fileno $stdout->[WRITE] or die "STDOUT: $!";
  select STDERR;
  $| = 1;
  select STDOUT;
  $| = 1;

  %ENV = _emulate_environment($c, $args);
  $args->{run} ? $args->{run}->($c) : exec $args->{script}
    || die "Could not execute $args->{script}: $!";

  eval { POSIX::_exit($!) } unless IS_WINDOWS;
  eval { CORE::kill KILL => $$ };
  exit $!;
}

sub _emulate_environment {
  my ($c, $args) = @_;
  my $tx             = $c->tx;
  my $req            = $tx->req;
  my $headers        = $req->headers;
  my $content_length = $req->content->is_multipart ? $req->body_size : $headers->content_length;
  my %env_headers    = (HTTP_COOKIE => '', HTTP_REFERER => '');
  my ($remote_user, $script_name);

  for my $name (@{$headers->names}) {
    my $key = uc "http_$name";
    $key =~ s!\W!_!g;
    $env_headers{$key} = $headers->header($name);
  }

  if (my $userinfo = $c->req->url->to_abs->userinfo) {
    $remote_user = $userinfo =~ /([^:]+)/ ? $1 : '';
  }
  elsif (my $authenticate = $headers->authorization) {
    $remote_user = $authenticate =~ /Basic\s+(.*)/ ? b64_decode $1 : '';
    $remote_user = $remote_user =~ /([^:]+)/       ? $1            : '';
  }

  if ($args->{route}) {
    $script_name = $c->url_for($args->{route}->name, {path_info => ''})->path->to_string;
  }
  elsif (my $name = $c->stash('script_name')) {
    my $name = quotemeta $name;
    $script_name = $c->req->url->path =~ m!^(.*?/$name)! ? $1 : $c->stash('script_name');
  }

  return (
    %{$args->{env}},
    CONTENT_LENGTH => $content_length        || 0,
    CONTENT_TYPE   => $headers->content_type || '',
    GATEWAY_INTERFACE => 'CGI/1.1',
    HTTPS             => $req->is_secure ? 'YES' : 'NO',
    %env_headers,
    PATH_INFO => '/' . encode('UTF-8', $c->stash('path_info') // ''),
    QUERY_STRING => $c->stash('cgi.query_string') || $req->url->query->to_string,
    REMOTE_ADDR => $tx->remote_address,
    REMOTE_HOST => gethostbyaddr(inet_aton($tx->remote_address || '127.0.0.1'), AF_INET) || '',
    REMOTE_PORT => $tx->remote_port,
    REMOTE_USER => $remote_user || '',
    REQUEST_METHOD  => $req->method,
    SCRIPT_FILENAME => $args->{script} || '',
    SCRIPT_NAME     => $script_name || $args->{name},
    SERVER_ADMIN    => $ENV{USER} || '',
    SERVER_NAME     => hostname,
    SERVER_PORT     => $tx->local_port,
    SERVER_PROTOCOL => $req->is_secure ? 'HTTPS' : 'HTTP',    # TODO: Version is missing
    SERVER_SOFTWARE => __PACKAGE__,
  );
}

sub _run {
  my ($defaults, $c) = (shift, shift);
  my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};
  my $before = $args->{before} || $defaults->{before};
  my $stdin  = _stdin($c);
  my @stdout = pipely;
  my ($pid, $log_key, @stderr);

  $args->{$_} ||= $defaults->{$_} for qw(env errlog route run script);
  $args->{name} = $args->{run} ? "$args->{run}" : basename $args->{script};
  $c->$before($args) if $before;
  @stderr = (pipely) unless $args->{errlog};
  defined($pid = fork) or die "[CGI:$args->{name}] fork failed: $!";
  _child($c, $args, $stdin, \@stdout, \@stderr) unless $pid;
  $args->{pids}{$pid} = $args->{name};
  $log_key = "CGI:$args->{name}:$pid";
  $c->app->log->debug("[$log_key] START @{[$args->{script} || $args->{run}]}");

  for my $p (\@stdout, \@stderr) {
    next unless $p->[READ];
    close $p->[WRITE];
    $p->[READ] = Mojo::IOLoop::Stream->new($p->[READ])->timeout(0);
    Mojo::IOLoop->stream($p->[READ]);
  }

  $c->stash('cgi.pid' => $pid, 'cgi.stdin' => $stdin);
  $c->render_later;

  $stderr[READ]->on(read => _stderr_cb($c, $log_key)) if $stderr[READ];
  $stdout[READ]->on(read => _stdout_cb($c, $log_key));
  $stdout[READ]->on(close => sub {
      my $GUARD = 50;
      warn "[CGI:$args->{name}:$pid] Child closed STDOUT\n" if DEBUG;
      unlink $stdin->path or die "Could not remove STDIN @{[$stdin->path]}" if -e $stdin->path;
      local ($?, $!);
      _waitpids({$pid => $args->{pids}{$pid}})
        while $args->{pids}{$pid}
        and kill 0, $pid
        and $GUARD--;
      $defaults->{pids}{$pid} = $args->{pids}{$pid} if kill 0, $pid;
      return $c->finish if $c->res->code;
      return $c->render(text => "Could not run CGI script ($?, $!).\n", status => 500);
    }
  );
}

sub _stderr_cb {
  my ($c, $log_key) = @_;
  my $log = $c->app->log;
  my $buf = '';

  return sub {
    my ($stream, $chunk) = @_;
    warn "[$log_key] !!! ($chunk)\n" if DEBUG;
    $buf .= $chunk;
    $log->warn("[$log_key] $1") while $buf =~ s!^(.+)[\r\n]+$!!m;
  };
}

sub _stdout_cb {
  my ($c, $log_key) = @_;
  my $buf = '';
  my $headers;

  return sub {
    my ($stream, $chunk) = @_;
    warn "[$log_key] >>> ($chunk)\n" if DEBUG;

    # true if HTTP header has been written to client
    return $c->write($chunk) if $headers;

    $buf .= $chunk;

    # false until all headers has been read from the CGI script
    $buf =~ s/^(.*?\x0a\x0d?\x0a\x0d?)//s or return;
    $headers = $1;

    if ($headers =~ /^HTTP/) {
      $c->res->code($headers =~ m!^HTTP (\d\d\d)! ? $1 : 200);
      $c->res->parse($headers);
    }
    else {
      $c->res->code($1) if $headers =~ /^Status: (\d\d\d)/m;
      $c->res->code($headers =~ /Location:/ ? 302 : 200) unless $c->res->code;
      $c->res->parse($c->res->get_start_line_chunk(0) . $headers);
    }
    $c->write($buf) if length $buf;
  };
}

sub _stdin {
  my $c = shift;
  my $stdin;

  if ($c->req->content->is_multipart) {
    $stdin = Mojo::Asset::File->new;
    $stdin->add_chunk($c->req->build_body);
  }
  else {
    $stdin = $c->req->content->asset;
  }

  return $stdin if $stdin->isa('Mojo::Asset::File');
  return Mojo::Asset::File->new->add_chunk($stdin->slurp);
}

sub _waitpids {
  my $pids = shift;

  for my $pid (keys %$pids) {

    # no idea why i need to do this, but it seems like waitpid() below return -1 if not
    local $SIG{CHLD} = 'DEFAULT';
    next unless waitpid $pid, WNOHANG;
    my $name = delete $pids->{$pid} || 'unknown';
    my ($exit_value, $signal) = ($? >> 8, $? & 127);
    warn "[CGI:$name:$pid] Child exit_value=$exit_value ($signal)\n" if DEBUG;
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::CGI - Run CGI script from Mojolicious

=head1 VERSION

0.40

=head1 DESCRIPTION

This plugin enables L<Mojolicious> to run Perl CGI scripts. It does so by forking
a new process with a modified environment and reads the STDOUT in a non-blocking
manner.

=head1 SYNOPSIS

=head2 Standard usage

  use Mojolicious::Lite;
  plugin CGI => [ "/cgi-bin/script" => "/path/to/cgi/script.pl" ];

Using the code above is enough to run C<script.pl> when accessing
L<http://localhost:3000/cgi-bin/script>.

=head2 Complex usage

  plugin CGI => {
    # Specify the script and mount point
    script => "/path/to/cgi/script.pl",
    route  => "/some/route",

    # %ENV variables visible from inside the CGI script
    env => {}, # default is \%ENV

    # Path to where STDERR from cgi script goes
    errlog => "/path/to/file.log",

    # The "before" hook is called before script start
    # It receives a Mojolicious::Controller which can be modified
    before => sub {
      my $c = shift;
      $c->req->url->query->param(a => 123);
    },
  };

The above contains all the options you can pass on to the plugin.

=head2 Helper

  plugin "CGI";

  # GET /cgi-bin/some-script.cgi/path/info?x=123
  get "/cgi-bin/#script_name/*path_info" => {path_info => ''}, sub {
    my $c    = shift;
    my $name = $c->stash("script_name");
    $c->cgi->run(script => File::Spec->rel2abs("/path/to/cgi/$name"));
  };

The helper can take most of the arguments that L</register> takes, with the
exception of C<support_semicolon_in_query_string>.

It is critical that "script_name" and "path_info" is present in
L<stash|Mojolicious::Controller/stash>. Whether the values are extracted directly
from the path or set manually does not matter.

Note that the helper is registered in all of the examples.

=head2 Running code refs

  plugin CGI => {
    route => "/some/path",
    run   => sub {
      my $cgi = CGI->new;
      # ...
    }
  };

Instead of calling a script, you can run a code block when accessing the route.
This is (pretty much) safe, even if the code block modifies global state,
since it runs in a separate fork/process.

=head2 Support for semicolon in query string

  plugin CGI => {
    support_semicolon_in_query_string => 1,
    ...
  };

The code above needs to be added before other plugins or handlers which use
L<Mojo::Message::Request/url>. It will inject a C<before_dispatch>
hook which saves the original QUERY_STRING, before it is split on
"&" in L<Mojo::Parameters>.

=head1 ATTRIBUTES

=head2 env

Holds a hash ref containing the environment variables that should be
used when starting the CGI script. Defaults to C<%ENV> when this module
was loaded.

This plugin will create a set of environment variables depenendent on the
request passed in which is according to the CGI spec. In addition to L</env>,
these dynamic variables are set:

  CONTENT_LENGTH, CONTENT_TYPE, HTTPS, PATH, PATH_INFO, QUERY_STRING,
  REMOTE_ADDR, REMOTE_HOST, REMOTE_PORT, REMOTE_USER, REQUEST_METHOD,
  SCRIPT_NAME, SERVER_PORT, SERVER_PROTOCOL.

Additional static variables:

  GATEWAY_INTERFACE = "CGI/1.1"
  SERVER_ADMIN = $ENV{USER}
  SCRIPT_FILENAME = Script name given as argument to register.
  SERVER_NAME = Sys::Hostname::hostname()
  SERVER_SOFTWARE = "Mojolicious::Plugin::CGI"

Plus all headers are exposed. Examples:

  .----------------------------------------.
  | Header          | Variable             |
  |-----------------|----------------------|
  | Referer         | HTTP_REFERER         |
  | User-Agent      | HTTP_USER_AGENT      |
  | X-Forwarded-For | HTTP_X_FORWARDED_FOR |
  '----------------------------------------'

=head2 register

  $self->register($app, [ $route => $script ]);
  $self->register($app, %args);
  $self->register($app, \%args);

C<route> and L<path> need to exist as keys in C<%args> unless given as plain
arguments.

C<$route> can be either a plain path or a route object.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
