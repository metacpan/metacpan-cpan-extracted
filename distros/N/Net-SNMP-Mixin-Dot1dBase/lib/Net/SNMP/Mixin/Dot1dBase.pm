package Net::SNMP::Mixin::Dot1dBase;

use strict;
use warnings;

#
# store this package name in a handy variable,
# used for unambiguous prefix of mixin attributes
# storage in object hash
#
my $prefix = __PACKAGE__;

#
# this module import config
#
use Carp ();
use Net::SNMP::Mixin::Util qw/idx2val normalize_mac push_error get_init_slot/;

#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (
    qw/
      get_dot1d_base_group
      map_bridge_ports2if_indexes
      map_if_indexes2bridge_ports
      /
  );
}

use Sub::Exporter -setup => {
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods], },
};

#
# SNMP oid constants used in this module
#
use constant {
  DOT1D_BASE_BRIDGE_ADDRESS => '1.3.6.1.2.1.17.1.1.0',
  DOT1D_BASE_NUM_PORTS      => '1.3.6.1.2.1.17.1.2.0',
  DOT1D_BASE_TYPE           => '1.3.6.1.2.1.17.1.3.0',

  DOT1D_BASE_PORT_IF_INDEX => '1.3.6.1.2.1.17.1.4.1.2',
};

=head1 NAME

Net::SNMP::Mixin::Dot1dBase - mixin class for the switch dot1d base values

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

A Net::SNMP mixin class for Dot1d base info.

  use Net::SNMP;
  use Net::SNMP::Mixin;

  # class based mixin
  Net::SNMP->mixer('Net::SNMP::Mixin::Dot1dBase');

  # ...

  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );

  $session->mixer('Net::SNMP::Mixin::Dot1dBase');
  $session->init_mixins;
  snmp_dispatcher() if $session->nonblocking;
  $session->init_ok;
  die $session->errors if $session->errors;

  my $base_group = $session->get_dot1d_base_group;

  printf "BridgeAddr: %s NumPorts: %d Type: %d\n",
    $base_group->{dot1dBaseBridgeAddress},
    $base_group->{dot1dBaseNumPorts},
    $base_group->{dot1dBaseType};

  my $map = $session->map_bridge_ports2if_indexes;

  foreach my $bridge_port ( sort {$a <=> $b} keys %$map ) {
    my $if_index = $map->{$bridge_port};
    printf "bridgePort: %4d -> ifIndex: %4\n", $bridge_port, $if_index;
  }


=head1 DESCRIPTION

A mixin class for basic switch information from the BRIDGE-MIB.

Besides the bridge address and the number of bridge ports, it's primary use is the mapping between dot1dBasePorts and ifIndexes.

=head1 MIXIN METHODS

=head2 B<< OBJ->get_dot1d_base_group() >>

Returns the dot1dBase group as a hash reference:

  {
    dot1dBaseBridgeAddress => MacAddress,
    dot1dBaseNumPorts      => INTEGER,
    dot1dBaseType          => INTEGER,
  }

=cut

sub get_dot1d_base_group {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  my $result = { %{ $session->{$prefix}{dot1dBase} } };

  # normalize the MAC address
  $result->{dot1dBaseBridgeAddress} =
    normalize_mac( $result->{dot1dBaseBridgeAddress} );

  return $result;
}

=head2 B<< OBJ->map_bridge_ports2if_indexes() >>

Returns a reference to a hash with the following entries:

  {
    # INTEGER        INTEGER
    dot1dBasePort => dot1dBasePortIfIndex,
  }

=cut

sub map_bridge_ports2if_indexes {
  my ( $session, ) = @_;
  my $agent = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # datastructure:
  # $session->{$prefix}{dot1dBasePortIfIndex}{$dot1d_base_port} = ifIndex
  #

  my $result = {};

  while ( my ( $bridge_port, $if_index ) = each %{ $session->{$prefix}{dot1dBasePortIfIndex} } ) {
    $result->{$bridge_port} = $if_index;
  }

  return $result;
}

=head2 B<< OBJ->map_if_indexes2bridge_ports() >>

Returns a reference to a hash with the following entries:

  {
    # INTEGER               INTEGER
    dot1dBasePortIfIndex => dot1dBasePort ,
  }

=cut

sub map_if_indexes2bridge_ports {
  my ( $session, ) = @_;
  my $agent = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # datastructure:
  # $session->{$prefix}{dot1dBasePortIfIndex}{$dot1d_base_port} = ifIndex
  #

  my $result = {};

  while ( my ( $bridge_port, $if_index ) = each %{ $session->{$prefix}{dot1dBasePortIfIndex} } ) {
    $result->{$if_index} = $bridge_port;
  }

  return $result;
}

=head1 INITIALIZATION

=cut

=head2 B<< OBJ->_init($reload) >>

Fetch the dot1d base related snmp values from the host. Don't call this method direct!

=cut

#
# due to the asynchron nature, we don't know what init job is really the last, we decrement
# the value after each callback
#
use constant THIS_INIT_JOBS => 2;

sub _init {
  my ( $session, $reload ) = @_;
  my $agent = $session->hostname;

  die "$agent: $prefix already initialized and reload not forced.\n"
    if exists get_init_slot($session)->{$prefix}
    && get_init_slot($session)->{$prefix} == 0
    && not $reload;

  # set number of async init jobs for proper initialization
  get_init_slot($session)->{$prefix} = THIS_INIT_JOBS;

  # initialize the object for dot1dbase infos
  _fetch_dot1d_base($session);
  return if $session->error;

  # LLDP, Dot1Q, STP, LLDP, ... tables are indexed
  # by dot1dbaseports and not ifIndexes
  # table to map between dot1dBasePort <-> ifIndex

  _fetch_dot1d_base_ports($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_dot1d_base($session) >>

Fetch values from the dot1dBase group once during object initialization.

=cut

sub _fetch_dot1d_base {
  my $session = shift;
  my $result;

  # fetch the dot1dBase group
  $result = $session->get_request(
    -varbindlist => [

      DOT1D_BASE_BRIDGE_ADDRESS,
      DOT1D_BASE_NUM_PORTS,
      DOT1D_BASE_TYPE,
    ],

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_dot1d_base_cb ) : (),
  );

  unless ( defined $result ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # in nonblocking mode the callback will be called asynchronously
  return 1 if $session->nonblocking;

  # call the callback function in blocking mode by hand
  _dot1d_base_cb($session);

}

=head2 B<< _dot1d_base_cb($session) >>

The callback for _fetch_dot1d_base.

=cut

sub _dot1d_base_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  $session->{$prefix}{dot1dBase}{dot1dBaseBridgeAddress} =
    $vbl->{ DOT1D_BASE_BRIDGE_ADDRESS() };

  $session->{$prefix}{dot1dBase}{dot1dBaseNumPorts} =
    $vbl->{ DOT1D_BASE_NUM_PORTS() };

  $session->{$prefix}{dot1dBase}{dot1dBaseType} = $vbl->{ DOT1D_BASE_TYPE() };

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head2 B<< _fetch_dot1d_base_ports($session) >>

Populate the object with the dot1dBasePorts.

=cut

sub _fetch_dot1d_base_ports {
  my $session = shift;
  my $result;

  # fetch the dot1dBasePorts, in blocking or nonblocking mode
  $result = $session->get_entries(
    -columns => [ DOT1D_BASE_PORT_IF_INDEX, ],

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_dot1d_base_ports_cb ) : (),
  );

  unless ( defined $result ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # in nonblocking mode the callback will be called asynchronously
  return 1 if $session->nonblocking;

  # call the callback funktion in blocking mode by hand
  _dot1d_base_ports_cb($session);

}

=head2 B<< _dot1d_base_ports_cb($session) >>

The callback for _fetch_dot1d_base_ports.

=cut

sub _dot1d_base_ports_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # mangle result table to get plain idx->value

  $session->{$prefix}{dot1dBasePortIfIndex} =
    idx2val( $vbl, DOT1D_BASE_PORT_IF_INDEX );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2021 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

unless ( caller() ) {
  print "$prefix compiles and initializes successful.\n";
}

1;

# vim: sw=2
