package Net::SNMP::Mixin::Dot1qVlanStatic;

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
use Net::SNMP::Mixin::Util qw/idx2val hex2octet get_init_slot/;

#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (
    qw/
      map_vlan_static_ports2ids
      map_vlan_static_ids2ports
      map_vlan_static_ids2names
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
  DOT1D_BASE_NUM_PORTS => '1.3.6.1.2.1.17.1.2.0',

  DOT1Q_VLAN_STATIC_NAME           => '1.3.6.1.2.1.17.7.1.4.3.1.1',
  DOT1Q_VLAN_STATIC_EGRESS_PORTS   => '1.3.6.1.2.1.17.7.1.4.3.1.2',
  DOT1Q_VLAN_STATIC_UNTAGGED_PORTS => '1.3.6.1.2.1.17.7.1.4.3.1.4',
  DOT1Q_VLAN_STATIC_ROW_STATUS     => '1.3.6.1.2.1.17.7.1.4.3.1.5',
};

=head1 NAME

Net::SNMP::Mixin::Dot1qVlanStatic - mixin class for 802.1-Q static vlan infos

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin qw/mixer init_mixins/;

  my $session = Net::SNMP->session( -hostname  => 'foo.bar.com');
  $session->mixer('Net::SNMP::Mixin::Dot1qVlanStatic');
  $session->init_mixins;
  snmp_dispatcher() if $session->nonblocking;
  $session->init_ok();
  die $session->errors if $session->errors;

  my $vlan_ids2names = $session->map_vlan_static_ids2names();
  foreach my $vlan_id ( keys %{$vlan_ids2names} ) {
    printf "Vlan-Id: %4d  => Vlan-Name: %s\n",
      $vlan_id, $vlan_ids2names->{$vlan_id};
  }

  # sorted by vlan_id
  my $vlan_ids2ports = $session->map_vlan_static_ids2ports();
  foreach my $vlan_id ( keys %{$vlan_ids2ports} ) {
    printf "Vlan-Id: %4d\n", $vlan_id;
    printf "\tTagged-Ports:     %s\n",
      ( join ',', @{ $vlan_ids2ports->{$vlan_id}{tagged} } );
    printf "\tUntagged-Ports:   %s\n",
      ( join ',', @{ $vlan_ids2ports->{$vlan_id}{untagged} } );
  }

  # sorted by bridge_port
  my $vlan_ports2ids = $session->map_vlan_static_ports2ids();
  foreach my $bridge_port ( keys %{$vlan_ports2ids} ) {
    printf "Bridge-Port: %4d\n", $bridge_port;
    printf "\tTagged-Vlans:     %s\n",
      ( join ',', @{ $vlan_ports2ids->{$bridge_port}{tagged} } );
    printf "\tUntagged-Vlans:   %s\n",
      ( join ',', @{ $vlan_ports2ids->{$bridge_port}{untagged} } );
  }

=head1 DESCRIPTION

A mixin class for vlan related infos from the dot1qVlanStaticTable within the Q-BRIDGE-MIB. The mixin-module provides methods for mapping between vlan-ids and vlan-names und relations between bridge-ports and vlan-ids, tagged or untagged on these ports.

=head1 MIXIN METHODS

=head2 B<< OBJ->map_vlan_static_ids2names() >>

Returns a hash reference with statically configured vlan-ids as keys and the corresponing vlan-names as values:

  {
    vlan_id => vlan_name,
    vlan_id => vlan_name,
    ... ,
  }

=cut

sub map_vlan_static_ids2names {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  my @active_vlan_ids  = @{$session->{$prefix}{activeVlanIds}};

  my $result = {};
  foreach my $vlan_id (@active_vlan_ids) {

    $result->{$vlan_id} = $session->{$prefix}{dot1qVlanStaticNames}{$vlan_id};
  }

  return $result;
}

=head2 B<< OBJ->map_vlan_static_ids2ports() >>

Returns a hash reference with the vlan-ids as keys and tagged and untagged port-lists as values:

  {
    vlan_id => {
      tagged   => [port_list],
      untagged => [port_list],
    },

    vlan_id => {
      tagged   => [port_list],
      untagged => [port_list],
    },

    ... ,
  }
    
=cut

sub map_vlan_static_ids2ports {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  my $num_bridge_ports = $session->{$prefix}{dot1dBaseNumPorts};
  my @active_vlan_ids  = @{$session->{$prefix}{activeVlanIds}};

  my $result;

  # loop over all active vlan ids
  foreach my $vlan_id (@active_vlan_ids) {

    # tagged/untagged ports for this vlan_id
    my @tagged_ports;
    my @untagged_ports;

    # loop over all possible bridge-ports
    foreach my $bridge_port ( 1 .. $num_bridge_ports ) {

      push @tagged_ports, $bridge_port
        if _is_tagged( $session, $bridge_port, $vlan_id );

      push @untagged_ports, $bridge_port
        if _is_untagged( $session, $bridge_port, $vlan_id );
    }

    $result->{$vlan_id} =
      { tagged => \@tagged_ports, untagged => \@untagged_ports };
  }
  return $result;
}

=head2 B<< OBJ->map_vlan_static_ports2ids() >>

Returns a hash reference with the bridge-ports as keys and tagged and untagged vlan-ids as values:

  {
    bridge_port => {
      tagged   => [vlan_id_list],
      untagged => [vlan_id_list],
    },

    bridge_port => {
      tagged   => [vlan_id_list],
      untagged => [vlan_id_list],
    },

    ... ,
  }
    
    
=cut

sub map_vlan_static_ports2ids {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  my $num_bridge_ports = $session->{$prefix}{dot1dBaseNumPorts};
  my @active_vlan_ids  = @{$session->{$prefix}{activeVlanIds}};

  my $result = {};

  # loop over all possible bridge-ports
  foreach my $bridge_port ( 1 .. $num_bridge_ports ) {

    my @tagged_vlans;
    my @untagged_vlans;

    # loop over all active vlans
    foreach my $vlan_id (@active_vlan_ids) {

      push @tagged_vlans, $vlan_id
        if _is_tagged( $session, $bridge_port, $vlan_id );

      push @untagged_vlans, $vlan_id
        if _is_untagged( $session, $bridge_port, $vlan_id );
    }

    $result->{$bridge_port} =
      { tagged => \@tagged_vlans, untagged => \@untagged_vlans };
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

  # initialize the object for forwarding databases infos
  _fetch_dot1d_base_num_ports($session);
  return if $session->error;

  # initialize the object for current vlan tag infos
  _fetch_dot1q_vlan_static_tbl_entries($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_dot1d_base_num_ports($session) >>

Fetch dot1dBaseNumPorts from the dot1dBase group once during object initialization.

=cut

sub _fetch_dot1d_base_num_ports {
  my $session = shift;
  my $result;

  # fetch the dot1dBaseNumPorts group
  $result = $session->get_request(
    -varbindlist => [ DOT1D_BASE_NUM_PORTS, ],

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_dot1d_base_num_ports_cb ) : (),
  );

  return unless defined $result;
  return 1 if $session->nonblocking;

  # call the callback function in blocking mode by hand
  _dot1d_base_num_ports_cb($session);

}

=head2 B<< _dot1d_base_num_ports_cb($session) >>

The callback for _fetch_dot1d_base_num_ports.

=cut

sub _dot1d_base_num_ports_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  return unless defined $vbl;

  $session->{$prefix}{dot1dBaseNumPorts} = $vbl->{ DOT1D_BASE_NUM_PORTS() };

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head2 B<< _fetch_dot1q_vlan_static_tbl_entries() >>

Fetch the vlan tag info for current vlans.

=cut

sub _fetch_dot1q_vlan_static_tbl_entries {
  my $session = shift;
  my $result;

  # fetch the vlan tag info from dot1qVlanStaticTable
  $result = $session->get_entries(
    -columns => [
      DOT1Q_VLAN_STATIC_NAME,           DOT1Q_VLAN_STATIC_EGRESS_PORTS,
      DOT1Q_VLAN_STATIC_UNTAGGED_PORTS, DOT1Q_VLAN_STATIC_ROW_STATUS,
    ],

    # define callback if in nonblocking mode
    $session->nonblocking
    ? ( -callback => \&_dot1q_vlan_static_tbl_entries_cb )
    : (),

    # dangerous for snmp version 2c and 3, big values
    # snmp-error: Message size exceeded buffer maxMsgSize
    #
    $session->version ? ( -maxrepetitions => 3 ) : (),
  );

  return unless defined $result;
  return 1 if $session->nonblocking;

  # call the callback function in blocking mode by hand
  _dot1q_vlan_static_tbl_entries_cb($session);

}

=head2 B<< _dot1q_vlan_static_tbl_entries_cb($session) >>

The callback for _fetch_dot1q_vlan_static_tbl_entries_cb.

=cut

sub _dot1q_vlan_static_tbl_entries_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  return unless defined $vbl;

  # mangle result table to get plain
  # 	dot1qVlanIndex => value
  #
  $session->{$prefix}{dot1qVlanStaticNames} =
    idx2val( $vbl, DOT1Q_VLAN_STATIC_NAME );

  # dot1qVlanIndex => dot1qVlanStaticEgressPorts
  $session->{$prefix}{dot1qVlanStaticEgressPorts} =
    idx2val( $vbl, DOT1Q_VLAN_STATIC_EGRESS_PORTS, );

  # dot1qVlanIndex => dot1qVlanStaticUntaggedPorts
  $session->{$prefix}{dot1qVlanStaticUntaggedPorts} =
    idx2val( $vbl, DOT1Q_VLAN_STATIC_UNTAGGED_PORTS, );

  # dot1qVlanIndex => dot1qVlanStaticRowStatus
  $session->{$prefix}{dot1qVlanStaticRowStatus} =
    idx2val( $vbl, DOT1Q_VLAN_STATIC_ROW_STATUS, );

  $session->{$prefix}{activeVlanIds} = [
    grep { $session->{$prefix}{dot1qVlanStaticRowStatus}{$_} == 1 }
      keys %{ $session->{$prefix}{dot1qVlanStaticRowStatus} }
  ];

  _calc_tagged_untagged_ports($session);

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

# Process tag/untag information for each bridge base port
# once during object initialization.
sub _calc_tagged_untagged_ports {
  my $session = shift;

  # calculate the tagged ports for each vlan
  # this is a XOR function: egress ^ untagged

  # for all vlans
  foreach my $vlan ( @{ $session->{$prefix}{activeVlanIds} } ) {

    # calculate the tagged ports for each vlan
    # this is a XOR function: egress ^ untagged
    #
    my $egress_ports = $session->{$prefix}{dot1qVlanStaticEgressPorts}{$vlan};
    my $untagged_ports =
      $session->{$prefix}{dot1qVlanStaticUntaggedPorts}{$vlan};

    # It's importend, that the returned SNMP OCTET_STRINGs
    # were untranslated by Net::SNMP!
    # if already translated, we must reconvert it to a
    # pure OCTET-STRING.

    $egress_ports   = hex2octet($egress_ports);
    $untagged_ports = hex2octet($untagged_ports);

    my $tagged_ports = $egress_ports ^ $untagged_ports;

    # convert to bit-string
    $session->{$prefix}{TaggedPorts}{$vlan} = unpack( 'B*', $tagged_ports );
    $session->{$prefix}{UntaggedPorts}{$vlan} =
      unpack( 'B*', $untagged_ports );
  }
}

# returns true if $vlan_id is tagged on $bride_port
sub _is_tagged {
  my ( $session, $bridge_port, $vlan_id ) = @_;

  die "missing attribute 'bridge_port'" unless defined $bridge_port;
  die "missing attribute 'vlan_id'"     unless defined $vlan_id;

  # it's a bitstring, see the subroutine _calc_tagged_untagged_ports
  # substr() counts from 0, bridge_ports from 1
  my $is_tagged =
    substr( $session->{$prefix}{TaggedPorts}{$vlan_id}, $bridge_port - 1, 1 );

  return 1 if $is_tagged;
  return;
}

# returns true if $vlan_id is untagged on $bride_port
sub _is_untagged {
  my ( $session, $bridge_port, $vlan_id ) = @_;

  die "missing attribute 'bridge_port'" unless defined $bridge_port;
  die "missing attribute 'vlan_id'"     unless defined $vlan_id;

  # it's a bitstring, see the subroutine _calc_tagged_untagged_ports
  # substr() counts from 0, bridge_ports from 1
  my $is_untagged = substr( $session->{$prefix}{UntaggedPorts}{$vlan_id},
    $bridge_port - 1, 1 );

  return 1 if $is_untagged;
  return;
}

=head1 SEE ALSO

L<< Net::SNMP::Mixin::Dot1dBase >> for a mapping between ifIndexes and dot1dBasePorts.

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a bug or are experiencing difficulties that are not explained within the POD documentation, please submit a bug to the RT system (see link below). However, it would help greatly if you are able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not be forthcoming, please feel free to (politely) remind me by sending an email to gaissmai@cpan.org .

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin-Dot1qVlanStatic

=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2016 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

unless ( caller() ) {
  print "$prefix compiles and initializes successful.\n";
}

1;

# vim: sw=2
