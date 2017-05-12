package Monitoring::Reporter::Backend::NagiosLivestatus;
{
  $Monitoring::Reporter::Backend::NagiosLivestatus::VERSION = '0.01';
}
BEGIN {
  $Monitoring::Reporter::Backend::NagiosLivestatus::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Monitoring dashboard Nagios Backend

use Moose;
use namespace::autoclean;

use Monitoring::Livestatus;

has 'lsc' => (
    'is'      => 'rw',
    'isa'     => 'Monitoring::Livestatus',
    'lazy'    => 1,
    'builder' => '_init_lsc',
);

has '_mapping' => (
  'is'  => 'ro',
  'isa' => 'HashRef',
  'lazy'  => 1,
  'builder' => '_init_mapping',
);

has '_severity_mapping' => (
  'is'  => 'ro',
  'isa' => 'HashRef',
  'lazy' => 1,
  'builder' => '_init_severity_mapping',
);

has '_priority_mapping' => (
  'is'  => 'ro',
  'isa' => 'HashRef',
  'lazy' => 1,
  'builder' => '_init_priority_mapping',
);

extends 'Monitoring::Reporter::Backend';

with qw(Config::Yak::RequiredConfig Log::Tree::RequiredLogger);

sub _init_lsc {
  my $self = shift;

  my $lsc_peer = $self->config()->get( 'Monitoring::Reporter::Backend::'.$self->name().'::Peer', { Default => '/var/lib/nagios3/rw/livestatus.sock', }, );

  $self->logger()->log( message => 'Using LSC Peer: '.$lsc_peer, level => 'debug', );

  my $LSC = Monitoring::Livestatus::->new(
    'peer'  => $lsc_peer,
    'warnings' => 0,
    'verbose'  => 0,
  );

  return $LSC;
}

sub _init_mapping {
  my $self = shift;

  my $Mapping = {
    'priority'      => 'last_state',
    'host'          => 'host_display_name',
    'description'   => 'plugin_output',
    'hostid'        => undef,
    'triggerid'     => undef,
    'itemid'        => undef,
    'lastvalue'     => 'plugin_output',
    'lastclock'     => 'last_state_change',
    'lastchange'    => 'last_time_ok',
    'value'         => 'plugin_output',
    'comments'      => undef,
    'units'         => undef,
    'valuemapid'    => undef,
    'triggerpid'    => undef,
  };

  return $Mapping;
}

sub _init_priority_mapping {
  my $self = shift;

  my $PrioMapping = {
    '0'   => '1', # OK -> information
    '1'   => '4', # WARNING -> High
    '2'   => '5', # CRITICAL -> Disaster
  };
  return $PrioMapping;
}

sub _init_severity_mapping {
  my $self = shift;

  my $SevMapping = {
    '0'   => 'information',
    '1'   => 'high',
    '2'   => 'disaster',
  };

  return $SevMapping;
}

sub fetch {
  my $self = shift;
  my $query = shift;
  my @args = @_;

  my $refs = $self->lsc()->selectall_arrayref($query, { Slice => {}, });

  return $refs;
}

sub do {
  my $self = shift;
  my $query = shift;
  my @args = @_;

  return $self->lsc()->do($query, @args);
}

sub triggers {
  my $self = shift;

  my @rows = ();

  $self->logger()->log( message => 'Nagios-Triggers', level => 'debug', );

  #my $arr_refs = $self->fetch_n_store('GET services');
  my $arr_refs = $self->fetch('GET services');

  foreach my $e (@{$arr_refs}) {
    #print "Host: ".$e->{'host_display_name'}." - ".$e->{'description'}." - ".$e->{'plugin_output'}." - ".$e->{'last_state'}."  - ".$e->{'last_time_ok'}."\n";
    my $row = {};
    foreach my $to (keys %{$self->_mapping()}) {
      my $from = $self->_mapping()->{$to};
      if(defined($from)) {
        if($to eq 'priority') {
          $row->{$to} = $self->_priority_mapping()->{$e->{$from}};
          $row->{'severity'} = $self->_severity_mapping()->{$e->{$from}};
        } else {
          $row->{$to} = $e->{$from};
        }
      } else {
        $row->{$to} = 0;
      }
    }
    push(@rows, $row);
  }

  return \@rows;
}

sub disabled_actions {
  my $self = shift;

  return []; # TODO not supported?
}

sub enable_actions {
  my $self = shift;

  return []; # TODO not supported?
}

sub unsupported_items {
    my $self = shift;

    return []; # TODO not supported?
}

sub unattended_alarms {
    my $self = shift;
    
    return []; # TODO not supported
}

sub history {
    my $self = shift;

    return []; # TODO not supported?
}
__PACKAGE__->meta->make_immutable;

1; # End of Monitoring::Reporter

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Reporter::Backend::NagiosLivestatus - Monitoring dashboard Nagios Backend

=begin mapping

priority  - last_state
host      - host_display_name
description - plugin_output
hostid    - 0
triggerid - 0
itemid    - 0
lastvalue - plugin_output
lastclock - last_state_change
lastchange - last_time_ok
value     - plugin_output
comments  - ''
units     - ''
valuemapid - ''
triggerdepid - 0
=method fetch

Fetch a result directly from DB.

=method do

Execute an Stmt in the DB.

=method triggers

Retrieve all matching triggers.

=method disabled_actions

Retrieve all disabled actions.

=method enable_actions

Enables all actions.

=method unsupported_items

Retrieve all unsupported items.

=method unattended_alarms

Retrieve all unsupported items.

=method history

Retrieve all triggers.

=head1 NAME

Monitoring::Reporter - Monitoring dashboard


=end mapping

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
