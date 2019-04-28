package Mojolicious::Plugin::Syslog;
use Mojo::Base 'Mojolicious::Plugin';

use Sys::Syslog qw(:standard :macros);

our $VERSION = '0.01';

my %PRIORITY = (
  debug => LOG_DEBUG,
  error => LOG_ERR,
  fatal => LOG_CRIT,
  info  => LOG_INFO,
  warn  => LOG_WARNING,
);

sub register {
  my ($self, $app, $params) = @_;
  my %config = %{$params || {}};

  $config{enable} //= $ENV{MOJO_SYSLOG_ENABLE} // $app->mode ne 'development';
  return unless $config{enable};

  $config{facility} ||= $ENV{MOJO_SYSLOG_FACILITY} || LOG_USER;
  $config{ident}    ||= $ENV{MOJO_SYSLOG_IDENT}    || $app->moniker;
  $config{logopt}   ||= $ENV{MOJO_SYSLOG_LOGOPT}   || 'ndelay,pid';

  $config{access_log} //= $ENV{MOJO_SYSLOG_ACCESS_LOG};
  $config{access_log} = '%H "%P" (%I) %C %M (%Ts)'
    if ($config{access_log} || '') eq '1';

  openlog @config{qw(ident logopt facility)};
  $app->log->unsubscribe('message') if $config{only_syslog};
  $app->log->unsubscribe(message => \&_syslog);
  $app->log->on(message => \&_syslog);

  $self->_add_access_log($app, \%config) if $config{access_log};
}

sub _add_access_log {
  my ($self, $app, $config) = @_;

  $app->hook(
    before_routes => sub {
      shift->helpers->timing->begin(__PACKAGE__);
    }
  );

  $app->hook(
    after_dispatch => sub {
      my $c = shift;

      my $timing  = $c->helpers->timing;
      my $elapsed = $timing->elapsed(__PACKAGE__) // 0;

      my $req  = $c->req;
      my $res  = $c->res;
      my $code = $res->code;

      my %MSG = (
        C => $code,
        H => $req->method,
        I => $req->request_id,
        M => $res->message || $res->default_message($code),
        P => $req->url->path->to_abs_string,
        T => $elapsed,
      );

      my $level   = $res->is_server_error ? 'warn' : 'info';
      my $message = $config->{access_log};
      $message =~ s!\%([CHIMPRT])!$MSG{$1}!g;
      $c->app->log->$level($message);
    }
  );
}

sub _syslog {
  my ($log, $level, @lines) = @_;
  syslog $PRIORITY{$level}, '%s', $_ for map { chomp; $_ } @lines;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Syslog - A plugin for enabling a Mojolicious app to log to syslog

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin syslog => {facility => 'local0'};

=head1 DESCRIPTION

L<Mojolicious::Plugin::Syslog> is a L<Mojolicious> plugin for making
L<Mojo::Log> use L<Sys::Syslog> in addition (or instead) of file logging.

This can be useful when starting Hypnotoad through Systemd, but want simple
logging of error messages to syslog.

=head1 METHODS

=head2 register

  $app->plugin(syslog => \%config);
  $self->register($app, \%config);

Used to register the plugin in your L<Mojolicious> application. Available
config parameters are:

=over 2

=item * access_log

Used to enable logging of access to resources with a route enpoint. This means
that static files will not be logged, even if this option is enabled.

This can be "1" or a string. Will use the default format, if "1" is specified:

  %H "%P" (%I) %C %M (%Ts)
   |   |    |   |  |   \- Time in seconds for this request
   |   |    |   |  \- Response message, ex "OK"
   |   |    |   \- Response code, ex 200, 404, ...
   |   |    \- A unique identified for this request
   |   \- The path requested
   \- The HTTP method used, ex GET, POST ...

Default to the "MOJO_SYSLOG_ACCESS_LOG" environment variable or disabled by
default.

This feature and format is highly EXPERIMENTAL.

=item * enable

Need to be true to activate this plugin. Will use the "MOJO_SYSLOG_ENABLE"
environment variable or default to true if L<Mojolicious/mode> is something
else than "development"

=item * facility

The syslog facility to use. Default to "MOJO_SYSLOG_FACILITY" environment
variable or default to "user".

The default is EXPERIMENTAL.

=item * ident

The syslog ident to use. Default to "MOJO_SYSLOG_IDENT" environment variable or
L<Mojolicious/moniker>.

=item * only_syslog

Set this to true to disabled the default L<Mojo::Log> logging to file/stderr.

=back

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
