package Net::SNMP::Mixin::ArubaCX::VlanStatic;

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
use Carp      ();
use Net::SNMP ();
use Net::SNMP::Mixin::Util qw/idx2val hex2octet push_error get_init_slot/;
#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (
    qw/
      map_vlan_id2name
      map_if_idx2vlan_id
      map_vlan_id2if_idx
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

  # BRIDGE-MIB
  ############

  DOT1D_BASE_PORT_IF_INDEX => '1.3.6.1.2.1.17.1.4.1.2',

  # IEEE8021-Q-BRIDGE-MIB
  #######################

  #from IEEE8021_Q_BRIDGE_VLAN_STATIC_TABLE => '1.3.111.2.802.1.1.4.1.4.3',

  IEEE8021_Q_BRIDGE_VLAN_STATIC_NAME        => '1.3.111.2.802.1.1.4.1.4.3.1.3',
  IEEE8021_Q_BRIDGE_VLAN_STATIC_EGRESSPORTS => '1.3.111.2.802.1.1.4.1.4.3.1.4',
  IEEE8021_Q_BRIDGE_VLAN_STATIC_ROW_STATUS  => '1.3.111.2.802.1.1.4.1.4.3.1.7',

  # IEEE8021_Q_BRIDGE_VLAN_STATIC_UNTAGGED_PORTS => '1.3.111.2.802.1.1.4.1.4.3.1.6'

  # BUG until at least PL.10.08.0001
  # VLAN_STATIC_UNTAGGED_PORTS is identical to IEEE8021_Q_BRIDGE_VLAN_STATIC_EGRESSPORTS

  # Gimmick: use instead the Pvid (untagged) info from
  # from IEEE8021_Q_BRIDGE_PORT_VLAN_TABLE => '.1.3.111.2.802.1.1.4.1.4.5',
  IEEE8021_Q_BRIDGE_PVID => '.1.3.111.2.802.1.1.4.1.4.5.1.1',
};

=head1 NAME

Net::SNMP::Mixin::ArubaCX::VlanStatic - mixin class for ArubaCX static vlan info

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin qw/mixer init_mixins/;

  my $session = Net::SNMP->session( -hostname  => 'foo.bar.com');
  $session->mixer('Net::SNMP::Mixin::ArubaCX::VlanStatic');
  $session->init_mixins;
  snmp_dispatcher() if $session->nonblocking;
  $session->init_ok();
  die $session->errors if $session->errors;

  my $vlan_id2name = $session->map_vlan_id2name();
  foreach my $vlan_id ( keys %{$vlan_id2name} ) {
    printf "Vlan-Id: %4d  => Vlan-Name: %s\n",
      $vlan_id, $vlan_id2name->{$vlan_id};
  }

  my $vlan_ids2if_idx = $session->map_vlan_id2if_idx();
  foreach my $id ( keys %{$vlan_ids2if_idx} ) {
    printf "Vlan-Id: %4d\n", $id;
    printf "\tTagged-Ports:     %s\n", ( join ',', @{ $vlan_ids2if_idx->{$id}{tagged} } );
    printf "\tUntagged-Ports:   %s\n", ( join ',', @{ $vlan_ids2if_idx->{$id}{untagged} } );
  }

  # sorted by interface
  my $ports2ids = $session->map_if_idx2vlan_id();
  foreach my $if_idx ( keys %{$ports2ids} ) {
    printf "Interface: %10d\n", $if_idx;
    printf "\tTagged-Vlans:     %s\n", ( join ',', @{ $ports2ids->{$if_idx}{tagged} } );
    printf "\tUntagged-Vlans:   %s\n", ( join ',', @{ $ports2ids->{$if_idx}{untagged} } );
  }

=head1 DESCRIPTION

A mixin class for vlan related infos from the IEEE8021-Q-BRIDGE-MIB used by ArubaCX.

The mixin-module provides methods for mapping between vlan-ids and vlan-names und relations between interface indexes and vlan-ids,
tagged or untagged on these interfaces.

=head1 MIXIN METHODS

=head2 B<< OBJ->map_vlan_id2name() >>

Returns a hash reference with statically configured vlan-ids as keys and the corresponing vlan-names as values:

  {
    vlan_id => vlan_name,
    vlan_id => vlan_name,
    ... ,
  }

=cut

sub map_vlan_id2name {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  my @active_vlan_ids = @{ $session->{$prefix}{activeVlanIds} };

  my $result = {};
  foreach my $vlan_id (@active_vlan_ids) {

    $result->{$vlan_id} = $session->{$prefix}{VlanStaticNames}{$vlan_id};
  }

  return $result;
}

=head2 B<< OBJ->map_vlan_id2if_idx() >>

Returns a hash reference with the vlan-ids as keys and tagged and untagged if_idx as values:

  {
    vlan_id => {
      tagged   => [if_idx, ..., ],
      untagged => [if_idx, ..., ],
    },

    ... ,
  }
    
=cut

sub map_vlan_id2if_idx {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  my @active_vlan_ids    = @{ $session->{$prefix}{activeVlanIds} };
  my $bridge_port2if_idx = $session->{$prefix}{dot1dBasePortIfIndex};

  my $result;

  # loop over all active vlan ids
  foreach my $vlan_id (@active_vlan_ids) {

    # tagged/untagged ports for this vlan_id
    my @tagged_ports;
    my @untagged_ports;

    # loop over all possible bridge-ports
    foreach my $bridge_port ( sort { $a <=> $b } keys %$bridge_port2if_idx ) {
      my $if_idx = $bridge_port2if_idx->{$bridge_port};

      push @tagged_ports, $if_idx
        if _is_tagged( $session, $bridge_port, $vlan_id );

      push @untagged_ports, $if_idx
        if _is_untagged( $session, $bridge_port, $vlan_id );
    }

    $result->{$vlan_id} = { tagged => \@tagged_ports, untagged => \@untagged_ports };
  }
  return $result;
}

=head2 B<< OBJ->map_if_idx2vlan_id() >>

Returns a hash reference with the interfaces as keys and tagged and untagged vlan-ids as values:

  {
    if_idx => {
      tagged   => [vlan_id, ..., ],
      untagged => [vlan_id, ..., ],
    },

    ... ,
  }
    
=cut

sub map_if_idx2vlan_id {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  my @active_vlan_ids    = @{ $session->{$prefix}{activeVlanIds} };
  my $bridge_port2if_idx = $session->{$prefix}{dot1dBasePortIfIndex};

  my $result = {};

  # loop over all possible bridge-ports
  foreach my $bridge_port ( sort { $a <=> $b } keys %$bridge_port2if_idx ) {

    my @tagged_vlans;
    my @untagged_vlans;

    # loop over all active vlans
    foreach my $vlan_id (@active_vlan_ids) {

      push @tagged_vlans, $vlan_id
        if _is_tagged( $session, $bridge_port, $vlan_id );

      push @untagged_vlans, $vlan_id
        if _is_untagged( $session, $bridge_port, $vlan_id );
    }

    my $if_idx = $bridge_port2if_idx->{$bridge_port};
    $result->{$if_idx} = { tagged => \@tagged_vlans, untagged => \@untagged_vlans };
  }
  return $result;
}

=head1 INITIALIZATION

=head2 B<< OBJ->_init($reload) >>

Fetch basic Dot1Q Vlan related snmp values from the host. Don't call this method direct!

=cut

#
# due to the asynchron nature, we don't know what init job is really the last, we decrement
# the value after each callback
#
use constant THIS_INIT_JOBS => 3;

sub _init {
  my ( $session, $reload ) = @_;
  my $agent = $session->hostname;

  die "$agent: $prefix already initialized and reload not forced.\n"
    if exists get_init_slot($session)->{$prefix}
    && get_init_slot($session)->{$prefix} == 0
    && not $reload;

  # set number of async init jobs for proper initialization
  get_init_slot($session)->{$prefix} = THIS_INIT_JOBS;

  # bridge ports to ifIndex mapping
  _fetch_dot1d_base_ports($session);
  return if $session->error;

  # initialize the object for current vlan tag infos
  _fetch_ieee8021q_vlan_static_tbl_entries($session);
  return if $session->error;

  # initialize the object for pvid (untag) infos
  _fetch_ieee8021q_port_vlan_tbl_entries($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=cut

=head2 B<< _fetch_dot1d_base_ports() >>

Fetch the mapping between brigePort and ifIndex

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

  # call the callback function in blocking mode by hand
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

  $session->{$prefix}{dot1dBasePortIfIndex} = idx2val( $vbl, DOT1D_BASE_PORT_IF_INDEX );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head2 B<< _fetch_ieee8021q_vlan_static_tbl_entries() >>

Fetch the vlan tag info for current vlans.

=cut

sub _fetch_ieee8021q_vlan_static_tbl_entries {
  my $session = shift;
  my $result;

  # fetch the vlan tag info from ieee8021qVlanStaticTable
  $result = $session->get_entries(
    -columns => [
      IEEE8021_Q_BRIDGE_VLAN_STATIC_NAME,
      IEEE8021_Q_BRIDGE_VLAN_STATIC_EGRESSPORTS,
      IEEE8021_Q_BRIDGE_VLAN_STATIC_ROW_STATUS,
    ],

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_ieee8021q_vlan_static_tbl_entries_cb ) : (),

    # dangerous for snmp version 2c and 3, big values
    # snmp-error: Message size exceeded buffer maxMsgSize
    #
    $session->version ? ( -maxrepetitions => 3 ) : (),
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
  _ieee8021q_vlan_static_tbl_entries_cb($session);

}

=head2 B<< _ieee8021q_vlan_static_tbl_entries_cb($session) >>

The callback for _fetch_ieee8021q_vlan_static_tbl_entries_cb.

=cut

sub _ieee8021q_vlan_static_tbl_entries_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  #----------------------------------------------------------------------
  # ieee8021QBridgeVlanStaticEntry OBJECT-TYPE
  #   SYNTAX      Ieee8021QBridgeVlanStaticEntry
  #   MAX-ACCESS  not-accessible
  #   STATUS      current
  #   DESCRIPTION
  #       "Static information for a VLAN configured into the device by (local or network) management."
  #   INDEX   { ieee8021QBridgeVlanStaticComponentId, ieee8021QBridgeVlanStaticVlanIndex }
  #   ::= { ieee8021QBridgeVlanStaticTable 1 }
  #----------------------------------------------------------------------
  #
  # cut off the index ieee8021QBridgeVlanStaticComponentId with idx2val( $vbl, base_oid, 1, undef )
  #
  # mangle result table to get plain
  # VlanId => value
  #
  $session->{$prefix}{VlanStaticNames}       = idx2val( $vbl, IEEE8021_Q_BRIDGE_VLAN_STATIC_NAME,        1, undef );
  $session->{$prefix}{VlanStaticEgressPorts} = idx2val( $vbl, IEEE8021_Q_BRIDGE_VLAN_STATIC_EGRESSPORTS, 1, undef );
  $session->{$prefix}{VlanStaticRowStatus}   = idx2val( $vbl, IEEE8021_Q_BRIDGE_VLAN_STATIC_ROW_STATUS,  1, undef );

  $session->{$prefix}{activeVlanIds} = [
    grep { $session->{$prefix}{VlanStaticRowStatus}{$_} == 1 }
      keys %{ $session->{$prefix}{VlanStaticRowStatus} }
  ];

  foreach my $vlan ( @{ $session->{$prefix}{activeVlanIds} } ) {
    my $egress_ports = $session->{$prefix}{VlanStaticEgressPorts}{$vlan};

    # It's importend, that the returned SNMP OCTET_STRINGs
    # were untranslated by Net::SNMP!
    # if already translated, we must reconvert it to a pure OCTET-STRING.

    $egress_ports = hex2octet($egress_ports);

    $session->{$prefix}{EgressPorts}{$vlan} = unpack( 'B*', $egress_ports );
  }

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head2 B<< _fetch_ieee8021q_port_vlan_tbl_entries() >>

Fetch the pvid (untag) info for bridge ports.

=cut

sub _fetch_ieee8021q_port_vlan_tbl_entries {
  my $session = shift;
  my $result;

  # fetch the pvid untag info from ieee8021qPortVlanTable
  $result = $session->get_entries( -columns => [ IEEE8021_Q_BRIDGE_PVID, ],

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_port_pvids_cb ) : (),
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
  _port_pvids_cb($session);

}

=head2 B<< _port_pvids_cb($session) >>

The callback for _fetch_ieee8021q_port_vlan_tbl_entries.

=cut

sub _port_pvids_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  #---------------------------------------------------------------------------------------------------
  # ieee8021QBridgePortVlanEntry OBJECT-TYPE
  #   SYNTAX      Ieee8021QBridgePortVlanEntry
  #   MAX-ACCESS  not-accessible
  #   STATUS      current
  #   DESCRIPTION
  #       "Information controlling VLAN configuration for a port
  #       on the device.  This is indexed by ieee8021BridgeBasePort."
  #   AUGMENTS { ieee8021BridgeBasePortEntry }
  #   ::= { ieee8021QBridgePortVlanTable 1 }
  #---------------------------------------------------------------------------------------------------

  # AUGMENTS ieee8021BridgeBasePortEntry

  #---------------------------------------------------------------------------------------------------
  # ieee8021BridgeBasePortEntry OBJECT-TYPE
  #  SYNTAX      Ieee8021BridgeBasePortEntry
  #  MAX-ACCESS  not-accessible
  #  STATUS      current

  #  DESCRIPTION
  #      "A list of objects containing information for each port
  #       of the Bridge."
  #  INDEX  { ieee8021BridgeBasePortComponentId, ieee8021BridgeBasePort }
  #  ::= { ieee8021BridgeBasePortTable 1 }
  #---------------------------------------------------------------------------------------------------
  #
  # cut off the index ieee8021BridgeBasePortComponentId with idx2val( $vbl, base_oid, 1, undef )
  #
  # mangle result table to get plain
  # Port => VlanId
  #

  $session->{$prefix}{Pvid} = idx2val( $vbl, IEEE8021_Q_BRIDGE_PVID, 1, undef );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

# returns true if $vlan_id is tagged on $bridge_port
sub _is_tagged {
  my ( $session, $bridge_port, $vlan_id ) = @_;

  die "missing attribute 'bridge_port'" unless defined $bridge_port;
  die "missing attribute 'vlan_id'"     unless defined $vlan_id;

  # it's a bitstring,
  # substr() counts from 0, bridge_ports from 1
  my $egressed = substr( $session->{$prefix}{EgressPorts}{$vlan_id}, $bridge_port - 1, 1 );

  # VLAN is not egressed on this port -> false
  return unless $egressed;

  # VLAN is PVID (untagged) on this port -> false
  return if _is_untagged( $session, $bridge_port, $vlan_id );

  return 1;
}

# returns true if $vlan_id is pvid on $bridge_port
sub _is_untagged {
  my ( $session, $bridge_port, $vlan_id ) = @_;

  die "missing attribute 'bridge_port'" unless defined $bridge_port;
  die "missing attribute 'vlan_id'"     unless defined $vlan_id;

  return $session->{$prefix}{Pvid}{$bridge_port} == $vlan_id;
}

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 AUTHOR

 Johannes Deger <johannes.deger at uni-ulm.de>
 Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2021 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

unless ( caller() ) {
  print "$prefix compiles and initializes successful.\n";
}

1;

# vim: sw=2
