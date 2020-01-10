package Mojolicious::Plugin::Systemd;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::File 'path';
use Mojo::Util qw(trim unquote);

use constant DEBUG => $ENV{MOJO_SYSTEMD_DEBUG} || 0;

our $VERSION = '0.02';

has config_map => sub {
  return {
    hypnotoad => {
      accepts            => sub { (MOJO_SERVER_ACCEPTS            => 0) },
      backlog            => sub { (MOJO_SERVER_BACKLOG            => 0) },
      clients            => sub { (MOJO_SERVER_CLIENTS            => 0) },
      graceful_timeout   => sub { (MOJO_SERVER_GRACEFUL_TIMEOUT   => 0) },
      heartbeat_interval => sub { (MOJO_SERVER_HEARTBEAT_INTERVAL => 0) },
      heartbeat_timeout  => sub { (MOJO_SERVER_HEARTBEAT_TIMEOUT  => 0) },
      inactivity_timeout => sub { (MOJO_SERVER_INACTIVITY_TIMEOUT => 0) },
      listen          => sub { (MOJO_LISTEN                 => [qr{\s+}]) },
      pid_file        => sub { (MOJO_SERVER_PID_FILE        => '') },
      proxy           => sub { (MOJO_SERVER_PROXY           => 0) },
      requests        => sub { (MOJO_SERVER_REQUESTS        => 0) },
      spare           => sub { (MOJO_SERVER_SPARE           => 0) },
      upgrade_timeout => sub { (MOJO_SERVER_UPGRADE_TIMEOUT => 0) },
      workers         => sub { (MOJO_SERVER_WORKERS         => 0) },
    },
  };
};

sub register {
  my ($self, $app, $config) = @_;
  $self->_merge_config_map($config->{config_map}, $self->config_map)
    if $config->{config_map};

  my $file = $config->{service_file} || $ENV{SYSTEMD_SERVICE_FILE};
  $self->_parse_unit_file($file) if $file or $ENV{XDG_SESSION_ID};

  $self->_config_from_env($app->config, $self->config_map);
}

sub _config_from_env {
  my ($self, $config, $config_map) = @_;

  for my $k (sort keys %$config_map) {
    if (ref $config_map->{$k} eq 'HASH') {
      $self->_config_from_env($config->{$k} ||= {}, $config_map->{$k});
    }
    elsif (ref $config_map->{$k} eq 'CODE') {
      my ($ek, $template) = $config_map->{$k}->();
      warn sprintf "[Systemd] config %s=%s\n", $ek, $ENV{$ek} // '' if DEBUG;
      $config->{$k} = $self->_config_val($ENV{$ek}, $template)
        if defined $ENV{$ek};
    }
  }
}

sub _config_val {
  my ($self, $val, $template) = @_;
  return ref $template eq 'ARRAY' ? [split $template->[0], $val] : $val;
}

sub _merge_config_map {
  my ($self, $source, $target) = @_;

  for my $k (sort keys %$source) {
    if (!defined $source->{$k}) {
      delete $target->{$k};
    }
    elsif (ref $source->{$k} eq 'HASH') {
      $self->_merge_config_map($source->{$k}, $target->{$k} ||= {});
    }
    elsif (ref $source->{$k} eq 'CODE') {
      $target->{$k} = $source->{$k};
    }
  }
}

sub _parse_environment_file {
  my ($self, $file) = @_;
  warn sprintf "[Systemd] EnvironmentFile=%s\n", $file if DEBUG;

  my $flag = $file =~ s!^(-)!! ? $1 : '';
  return if $flag eq '-' and !-r $file;

  my $FH = path($file)->open;
  while (<$FH>) {
    $self->_set_environment($1, $2) if /^(\w+)=(.*)/;
  }
}

sub _parse_unit_file {
  my ($self, $file) = @_;

  warn sprintf "[Systemd] SYSTEMD_UNIT_FILE=%s\n", $file if DEBUG;
  my $UNIT = path($file || 'SYSTEMD_UNIT_FILE_MISSING')->open;
  while (<$UNIT>) {
    $self->_set_multiple_environment($1)       if /^\s*\bEnvironment=(.+)/;
    $self->_parse_environment_file(unquote $1) if /^\s*\bEnvironmentFile=(.+)/;
    $self->_unset_multiple_environment($1)     if /^\s*\bUnsetEnvironment=(.+)/;
  }
}

sub _set_environment {
  my ($self, $key, $val) = @_;
  warn sprintf "[Systemd] set %s=%s\n", $key, unquote($val // 'undef') if DEBUG;
  $ENV{$key} = unquote $val;
}

sub _set_multiple_environment {
  my ($self, $str) = @_;
  $str =~ s!\#.*!!;

  # "FOO=word1 word2" BAR=word3 "BAZ=$word 5 6" FOO="w=1"
  while ($str =~ m!("[^"]*"|\w+=\S+)!g) {
    my $expr = unquote $1;
    $self->_set_environment($1, $2) if $expr =~ /^(\w+)=(.*)/;
  }
}

sub _unset_multiple_environment {
  my ($self, $str) = @_;

  for my $k (map { trim unquote $_ } grep {length} split /\s+/, $str) {
    warn sprintf "[Systemd] unset %s\n", $k if DEBUG;
    delete $ENV{$k};
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Systemd - Configure your app from within systemd service file

=head1 SYNOPSIS

=head2 Example application

  package MyApp;
  use Mojo::Base "Mojolicious";
  sub startup {
    my $app = shift;
    $app->plugin("Systemd");
  }

=head2 Example systemd unit file

    [Unit]
    Description=MyApp service
    After=network.target

    [Service]
    Environment=SYSTEMD_SERVICE_FILE=/etc/systemd/system/my_app.service
    Environment=MOJO_SERVER_PID_FILE=/var/run/my_app.pid
    Environment=MYAPP_HOME=/var/my_app
    EnvironmentFile=-/etc/default/my_app

    User=www
    Type=forking
    PIDFile=/var/run/my_app.pid
    ExecStart=/path/to/hypnotoad /home/myapp/script/my_app
    ExecReload=/path/to/hypnotoad /home/myapp/script/my_app
    KillMode=process
    SyslogIdentifier=my_app

    [Install]
    WantedBy=multi-user.target

=head1 DESCRIPTION

L<Mojolicious::Plugin::Systemd> is a L<Mojolicious> plugin that allows your
application to read configuration from a Systemd service (unit) file.

It works by parsing the C<Environment>, C<EnvironmentFile> and
C<UnsetEnvironment> statements in the service file and inject those environment
variables into your application. This is especially useful if your application
is run by L<Mojo::Server::Hypnotoad>, since you cannot "inject" environment
variables into a running application, meaning C<SOME_VAR> below won't change
anything in your already started application:

  $ SOME_VAR=42 /path/to/hypnotoad /home/myapp/script/my_app

See L<http://manpages.ubuntu.com/manpages/cosmic/man5/systemd.exec.5.html#environment>
for more information about C<Environment>, C<EnvironmentFile> and C<UnsetEnvironment>.

=head1 ATTRIBUTES

=head2 config_map

  $hash_ref = $self->config_map;

Returns a structure for how L<Mojolicious/config> can be set from environment
variables. By default the environment variables below are supported:

  $app->config->{hypnotoad}{accepts}            = $ENV{MOJO_SERVER_ACCEPTS}
  $app->config->{hypnotoad}{backlog}            = $ENV{MOJO_SERVER_BACKLOG}
  $app->config->{hypnotoad}{clients}            = $ENV{MOJO_SERVER_CLIENTS}
  $app->config->{hypnotoad}{graceful_timeout}   = $ENV{MOJO_SERVER_GRACEFUL_TIMEOUT}
  $app->config->{hypnotoad}{heartbeat_interval} = $ENV{MOJO_SERVER_HEARTBEAT_INTERVAL}
  $app->config->{hypnotoad}{heartbeat_timeout}  = $ENV{MOJO_SERVER_HEARTBEAT_TIMEOUT}
  $app->config->{hypnotoad}{inactivity_timeout} = $ENV{MOJO_SERVER_INACTIVITY_TIMEOUT}
  $app->config->{hypnotoad}{listen}             = [split /\s+/, $ENV{MOJO_LISTEN}];
  $app->config->{hypnotoad}{pid_file}           = $ENV{MOJO_SERVER_PID_FILE}
  $app->config->{hypnotoad}{proxy}              = $ENV{MOJO_SERVER_PROXY}
  $app->config->{hypnotoad}{requests}           = $ENV{MOJO_SERVER_REQUESTS}
  $app->config->{hypnotoad}{spare}              = $ENV{MOJO_SERVER_SPARE}
  $app->config->{hypnotoad}{upgrade_timeout}    = $ENV{MOJO_SERVER_UPGRADE_TIMEOUT}
  $app->config->{hypnotoad}{workers}            = $ENV{MOJO_SERVER_WORKERS}

=head1 METHODS

=head2 register

  $app->plugin("Systemd");
  $app->plugin("Systemd" => {config_map => {...}, service_file => "..."});

Used to register the plugin in your application. The following options are
otional:

=over 2

=item * config_map

The C<config_map> must be a hash-ref and will be I<merged> with the
L</config_map> attribute. Example:

  $app->plugin(Systemd => {
    config_map => {
      # Add your own custom environment variables. The empty quotes means
      # that the environment variable should be read as a string.
      database => {
        url => sub { (MYAPP_DB_URL => "") },
      },
      hypnotoad => {
        # Remove support for the default MOJO_SERVER_ACCEPTS environment
        # variable
        accepts => undef,

        # Change the environment variable from MOJO_LISTEN and
        # the regexp to split the environment variable into a list
        listen  => sub { (MYAPP_LISTEN => [qr{[,\s]}]) },
      }
    }
  });

=item * service_file

Defaults to the environment variable C<SYSTEMD_SERVICE_FILE> and I<is> required
if C<XDG_SESSION_ID> is set. Must be a full path to where your service file is
located. See L</Example systemd unit file> for example.

=back

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019, Jan Henning Thorsen.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Plugin::Syslog>.

=cut
