package Mojo::Netdata;
use Mojo::Base -base, -signatures;

use IO::Handle;
use Mojo::File qw(path);
use Mojo::Netdata::Util qw(logf);

our $VERSION = '0.04';

has collectors       => sub ($self) { $self->_build_collectors };
has config           => sub ($self) { $self->_build_config };
has user_config_dir  => sub ($self) { $ENV{NETDATA_USER_CONFIG_DIR}  || '/etc/netdata' };
has stock_config_dir => sub ($self) { $ENV{NETDATA_STOCK_CONFIG_DIR} || '/usr/lib/netdata/conf.d' };
has plugins_dir      => sub ($self) { $ENV{NETDATA_PLUGINS_DIR}      || '' };
has web_dir          => sub ($self) { $ENV{NETDATA_WEB_DIR}          || '' };
has cache_dir        => sub ($self) { $ENV{NETDATA_CACHE_DIR}        || '' };
has log_dir          => sub ($self) { $ENV{NETDATA_LOG_DIR}          || '' };
has host_prefix      => sub ($self) { $ENV{NETDATA_HOST_PREFIX}      || '' };
has debug_flags      => sub ($self) { $ENV{NETDATA_DEBUG_FLAGS}      || '' };
has update_every     => sub ($self) { $ENV{NETDATA_UPDATE_EVERY}     || 1 };

sub start ($self) {
  logf(
    info => 'Starting %s with debug_flags=%s host_prefix=%s update_every=%s',
    ref($self), map { $self->$_ } qw(debug_flags host_prefix update_every),
  );
  return 0 unless @{$self->collectors};
  $_->emit_charts->recurring_update_p for @{$self->collectors};
  return int @{$self->collectors};
}

sub _build_config ($self) {
  my $config = {};

  my $file = path($self->user_config_dir, 'mojo.conf.pl')->to_abs;
  if (-r $file) {
    logf(debug => 'Loading config file %s into config().', $file);
    $config = _eval_file($file);
  }

  my $conf_d = path($self->user_config_dir, 'mojo.conf.d')->to_abs->list->sort;
  for my $file ($conf_d->each) {
    next unless $file->basename =~ m!\.conf\.pl$!;
    next unless my $d = _eval_file($file);

    if ($d->{collector}) {
      logf(debug => 'Adding config file %s to "collectors".', $file);
      push @{$config->{collectors}}, $d;
    }
    else {
      logf(debug => 'Merging config file %s into config().', $file);
      @$config{keys(%$d)} = values %$d;
    }
  }

  return $config;
}

sub _build_collectors ($self) {
  my $fh = $self->{stdout} // \*STDOUT;    # for testing
  $fh->autoflush;

  local $@;
  my @collectors;
  for my $collector_config (@{$self->config->{collectors} || []}) {
    my $collector_class = $collector_config->{collector};

    unless ($collector_class and $collector_class =~ m!^[\w:]+$!) {
      logf(error => 'Invalid collector_class %s', $collector_class || 'missing');
      next;
    }
    unless (eval "require $collector_class;1") {
      logf(error => 'Load %s FAIL %s', $collector_class, $@);
      next;
    }

    next unless my $collector = $collector_class->new->register($collector_config, $self);
    $collector->on(stdout => sub ($collector, $str) { $fh->print($str) });
    logf(debug => 'Loaded and set up %s', $collector_class);
    push @collectors, $collector;
  }

  return \@collectors;
}

sub _eval_file ($file) {
  local $@;
  my $prefix = 'package Mojo::Netdata::Config; no warnings; use Mojo::Base -strict;';
  my $config = eval $prefix . $file->slurp;
  logf(error => 'Config file "%s" is invalid: %s', $file, $@) if $@;
  return $config;
}

1;

=encoding utf8

=head1 NAME

Mojo::Netdata - https://netdata.cloud plugin for Perl

=head1 SYNOPSIS

=head2 Installation

  sudo -i
  apt install -y cpanminus
  cpanm -n https://github.com/jhthorsen/mojo-netdata/archive/refs/heads/main.tar.gz
  ln -s $(which mojo-netdata) /etc/netdata/custom-plugins.d/mojo-netdata.plugin

  # See "Config file" below for information on what to place inside mojo.conf.pl
  $EDITOR /etc/netdata/mojo.conf.pl

=head2 Config files

The config files are located in C</etc/netdata/mojo.conf.d>. The files are
plain Perl files, which means you can define variables and call functions. The
only important part is that the last statement in the file is a hash-ref.

Any hash-refs that has the "collector" key will be placed into L</collectors>,
while everything else will be merged into L</config>. Example:

  # /etc/netdata/mojo.conf.d/foo.conf.pl
  {foo => 42, bar => 100}

  # /etc/netdata/mojo.conf.d/bar.conf.pl
  {collector => 'Mojo::Netdata::Collector::HTTP', jobs => []}

The two config files above will result in this L</config>:

  {
    foo => 42,
    bar => 100,
    collectors => [
      {collector => 'Mojo::Netdata::Collector::HTTP', jobs => []},
    },
  }

See L<Mojo::Netdata::Collector::HTTP/SYNOPSIS> for an example config file.

=head2 Log file

The output from this Netdata plugin can be found in
C</var/log/netdata/error.log>.

=head1 DESCRIPTION

L<Mojo::Netdata> is a plugin for L<Netdata|https://netdata.cloud>. It can load
custom L<Mojo::Netdata::Collector> classes and write data back to Netdata on a
given interval.

This module is currently EXPERIMENTAL, and the API might change without
warning.

=head1 ATTRIBUTES

=head2 cache_dir

  $path = $netdata->cache_dir;

Holds the C<NETDATA_CACHE_DIR> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head2 config

  $hash_ref = $netdata->config;

Holds the config for L<Mojo::Netdata> and all L</collectors>.

=head2 collectors

  $array_ref = $netdata->collectors;

An array-ref of L<Mojo::Netdata::Collector> objects.

=head2 debug_flags

  $str = $netdata->debug_flags;

Defaults to the C<NETDATA_DEBUG_FLAGS> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head2 host_prefix

  $str = $netdata->host_prefix;

Defaults to the C<NETDATA_HOST_PREFIX> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head2 log_dir

  $path = $netdata->log_dir;

Holds the C<NETDATA_LOG_DIR> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head2 plugins_dir

  $path = $netdata->plugins_dir;

Holds the C<NETDATA_PLUGINS_DIR> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head2 stock_config_dir

  $path = $netdata->stock_config_dir;

Holds the C<NETDATA_STOCK_CONFIG_DIR> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head2 update_every

  $num = $netdata->update_every;

Defaults to the C<NETDATA_UPDATE_EVERY> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head2 user_config_dir

  $path = $netdata->user_config_dir;

Holds the C<NETDATA_USER_CONFIG_DIR> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head2 web_dir

  $path = $netdata->web_dir;

Holds the C<NETDATA_WEB_DIR> environment variable. See
L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d#environment-variables>
for more details.

=head1 METHODS

=head2 start

  $bool = $netdata->start;

Reads the L</config> and return 1 if any L</collectors> got registered.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://learn.netdata.cloud/docs/agent/collectors/plugins.d>.

=cut
