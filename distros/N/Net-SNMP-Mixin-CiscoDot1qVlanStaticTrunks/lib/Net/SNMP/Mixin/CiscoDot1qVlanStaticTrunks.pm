package Net::SNMP::Mixin::CiscoDot1qVlanStaticTrunks;

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

use Net::SNMP::Mixin::Util qw/idx2val hex2octet push_error get_init_slot/;

#
# this module export config
#
my @mixin_methods;

BEGIN {
	# Net::SNMP::Mixin::CiscoDot1qVlanStatic supports trunks and access ports
	warn "DEPRECATED: use Net::SNMP::Mixin::CiscoDot1qVlanStatic\n";

  @mixin_methods = (
    qw/
      cisco_vlan_ids2names
      cisco_vlan_ids2trunk_ports
      cisco_trunk_ports2vlan_ids
      /
  );
}

use Sub::Exporter -setup => {
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods], },
};

#
# SNMP oid constants from CISCO-VTP-MIB
#
use constant {
  VLAN_TBL   => '1.3.6.1.4.1.9.9.46.1.3.1',
  VLAN_STATE => '1.3.6.1.4.1.9.9.46.1.3.1.1.2',
  VLAN_NAME  => '1.3.6.1.4.1.9.9.46.1.3.1.1.4',

  VLAN_TRUNK_PORT_TBL              => '1.3.6.1.4.1.9.9.46.1.6.1',
  VLAN_TRUNK_PORT_VLANS_ENABLED_1K => '1.3.6.1.4.1.9.9.46.1.6.1.1.4',
  VLAN_TRUNK_PORT_ENCAPS_OPER_TYPE => '1.3.6.1.4.1.9.9.46.1.6.1.1.16',
  VLAN_TRUNK_PORT_VLANS_ENABLED_2K => '1.3.6.1.4.1.9.9.46.1.6.1.1.17',
  VLAN_TRUNK_PORT_VLANS_ENABLED_3K => '1.3.6.1.4.1.9.9.46.1.6.1.1.18',
  VLAN_TRUNK_PORT_VLANS_ENABLED_4K => '1.3.6.1.4.1.9.9.46.1.6.1.1.19',
};

=head1 DEPRECATED

Use the new modul L<Net::SNMP::Mixin::CiscoDot1qVlanStatic> instead, it supports trunk- AND access-ports

=head1 NAME

Net::SNMP::Mixin::CiscoDot1qVlanStaticTrunks - mixin class for static Cisco IEEE-trunks info

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin;

  # initialize session and mixin library
  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );
  $session->mixer('Net::SNMP::Mixin::CiscoDot1qVlanStaticTrunks');
  $session->init_mixins;
  snmp_dispatcher();
  $session->init_ok();
  die $session->errors if $session->errors;

  # show VLAN IDs and corresponding names
  my $id2name = $session->cisco_vlan_ids2names();
  foreach my $vlan_id ( keys %{$id2name} ) {
      printf "Vlan-Id: %4d  => Vlan-Name: %s\n", $vlan_id,
	$id2name->{$vlan_id};
  }

  # show ports for vlan_id
  my $id2port = $session->cisco_vlan_ids2trunk_ports();
  foreach my $vlan_id ( keys %{$id2port} ) {
      printf "Vlan-Id: %4d\n", $vlan_id;
      printf "\tTagged-Ports:     %s\n",
	( join ',', @{ $id2port->{$vlan_id} } );
  }

  # show tagged vlans for port
  my $port2id = $session->cisco_trunk_ports2vlan_ids();
  foreach my $port ( keys %{$port2id} ) {
      printf "Port: %s\n", $port;
      printf "\tVLANs:     %s\n", ( join ',', @{ $port2id->{$port} } );
  }

=head1 DESCRIPTION

A mixin class for vlan related infos from the CISCO-VTP-MIB for IEEE-trunks. The mixin-module provides methods for mapping between vlan-ids and vlan-names und relations between trunk-ports and tagged vlan-ids.

=head1 MIXIN METHODS

=head2 B<< OBJ->cisco_vlan_ids2names() >>

Returns a hash reference with statically configured vlan-ids as keys and the corresponing vlan-names as values:

  {
    vlan_id => vlan_name,
    vlan_id => vlan_name,
    ... ,
  }

=cut

sub cisco_vlan_ids2names {
  my $session = shift;
  Carp::croak "'$prefix' not initialized,"
    unless $session->{$prefix}{__initialized};

  return $session->{$prefix}{VlanName};
}

=head2 B<< OBJ->cisco_vlan_ids2trunk_ports() >>

Returns a hash reference with the vlan-ids as keys and tagged port-lists as values:

  {
    vlan_id => [port_list],
    vlan_id => [port_list],
    ... ,
  }
    
=cut

sub cisco_vlan_ids2trunk_ports {
  my $session = shift;
  Carp::croak "'$prefix' not initialized,"
    unless $session->{$prefix}{__initialized};

  delete $session->{$prefix}{vlans2ports};
  _calc_vlans2ports($session);

  return $session->{$prefix}{vlans2ports};
}

=head2 B<< OBJ->cisco_trunk_ports2vlan_ids() >>

Returns a hash reference with the ifIndexes as keys and tagged vlan-ids as values:

  {
    ifIndex => [vlan_id_list],
    ifIndex => [vlan_id_list],
    ... ,
  }
    
    
=cut

sub cisco_trunk_ports2vlan_ids {
  my $session = shift;
  Carp::croak "'$prefix' not initialized,"
    unless $session->{$prefix}{__initialized};

  delete $session->{$prefix}{ports2vlans};
  _calc_ports2vlans($session);

  return $session->{$prefix}{ports2vlans};
}

=head1 INITIALIZATION

=head2 B<< OBJ->_init($reload) >>

Fetch basic Cisco-VTP Dot1Q Vlan related snmp values from the host. Don't call this method direct!

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

  # initialize the object for vtp vlan table
  _fetch_vtp_vlan_tbl_entries($session);
  return if $session->error;

  # initialize the object for vtp vlan trunk port table
  _fetch_vtp_vlan_trunk_port_tbl_entries($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_vtp_vlan_tbl_entries($session) >>

Fetch selected rows from vtpVlanTable during object initialization.

=cut

sub _fetch_vtp_vlan_tbl_entries {
  my $session = shift;
  my $result;

  # fetch the vlan state and vlan name from vlanTable
  $result = $session->get_entries(
    -columns => [ VLAN_STATE, VLAN_NAME, ],

    # define callback if in nonblocking mode
    $session->nonblocking
    ? ( -callback => \&_vtp_vlan_tbl_entries_cb )
    : (),

    # dangerous for snmp version 2c and 3, big values
    # snmp-error: Message size exceeded buffer maxMsgSize
    #
    $session->version ? ( -maxrepetitions => 3 ) : (),
  );

  return unless defined $result;
  return 1 if $session->nonblocking;

  # call the callback function in blocking mode by hand
  _vtp_vlan_tbl_entries_cb($session);

}

=head2 B<< _vtp_vlan_tbl_entries_cb($session) >>

The callback for _fetch_vtp_vlan_tbl_entries.

=cut

sub _vtp_vlan_tbl_entries_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless (defined $vbl) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  # mangle result table to get plain
  # 	VlanIndex => vlan-state
  #
  $session->{$prefix}{VlanState} = idx2val( $vbl, VLAN_STATE, 1 );

  # mangle result table to get plain
  # 	VlanIndex => vlan-name
  #
  $session->{$prefix}{VlanName} = idx2val( $vbl, VLAN_NAME, 1 );

  foreach my $vlan_id ( keys %{ $session->{$prefix}{VlanName} } ) {

    # delete unless the vlan is operational(1), see CISCO-VTP-MIB
    delete $session->{$prefix}{VlanName}{$vlan_id}
      unless $session->{$prefix}{VlanState}{$vlan_id} == 1;

  }

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head2 B<< _fetch_vtp_vlan_trunk_port_tbl_entries($session) >>

Fetch selected rows from vlanTrunkPortTable during object initialization.

=cut

sub _fetch_vtp_vlan_trunk_port_tbl_entries {
  my $session = shift;
  my $result;

  # fetch selected entries from vlanTrunkPortTable
  $result = $session->get_entries(
    -columns => [
      VLAN_TRUNK_PORT_VLANS_ENABLED_1K, VLAN_TRUNK_PORT_VLANS_ENABLED_2K,
      VLAN_TRUNK_PORT_VLANS_ENABLED_3K, VLAN_TRUNK_PORT_VLANS_ENABLED_4K,
      VLAN_TRUNK_PORT_ENCAPS_OPER_TYPE,
    ],

    # define callback if in nonblocking mode
    $session->nonblocking
    ? ( -callback => \&_vtp_vlan_trunk_port_tbl_entries_cb ) : (),

    # dangerous for snmp version 2c and 3, big values
    # snmp-error: Message size exceeded buffer maxMsgSize
    #
    $session->version ? ( -maxrepetitions => 3 ) : (),
  );

  return unless defined $result;
  return 1 if $session->nonblocking;

  # call the callback function in blocking mode by hand
  _vtp_vlan_trunk_port_tbl_entries_cb($session);

}

=head2 B<< _vtp_vlan_trunk_port_tbl_entries_cb($session) >>

The callback for _fetch_vtp_vlan_trunk_port_tbl_entries_cb.

=cut

sub _vtp_vlan_trunk_port_tbl_entries_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless (defined $vbl) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  # mangle result table to get plain
  # 	ifIndex => vlans-enabled-bitstring
  #
  $session->{$prefix}{VlansEnabled1k} =
    idx2val( $vbl, VLAN_TRUNK_PORT_VLANS_ENABLED_1K, );

  $session->{$prefix}{VlansEnabled2k} =
    idx2val( $vbl, VLAN_TRUNK_PORT_VLANS_ENABLED_2K, );

  $session->{$prefix}{VlansEnabled3k} =
    idx2val( $vbl, VLAN_TRUNK_PORT_VLANS_ENABLED_3K, );

  $session->{$prefix}{VlansEnabled4k} =
    idx2val( $vbl, VLAN_TRUNK_PORT_VLANS_ENABLED_4K, );

  $session->{$prefix}{VlansEncapsOperType} =
    idx2val( $vbl, VLAN_TRUNK_PORT_ENCAPS_OPER_TYPE, );

  $session->{$prefix}{__initialized}++;

  foreach my $if_idx ( keys %{ $session->{$prefix}{VlansEncapsOperType} } ) {

    # delete keys unless the trunk is dot1Q(4), see CISCO-VTP-MIB
    if ( $session->{$prefix}{VlansEncapsOperType}{$if_idx} != 4 ) {

      delete $session->{$prefix}{VlansEnabled1k}{$if_idx};
      delete $session->{$prefix}{VlansEnabled2k}{$if_idx};
      delete $session->{$prefix}{VlansEnabled3k}{$if_idx};
      delete $session->{$prefix}{VlansEnabled4k}{$if_idx};
    }

  }

  _calc_vlans_enabled($session);

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

sub _calc_vlans_enabled {
  my $session = shift;

  # prepare fillmask, see below
  my $zeroes_1k = pack( 'B*', 0 x 1024 );

  foreach my $if_idx ( keys %{ $session->{$prefix}{VlansEnabled1k} } ) {

    # for all phys interfaces get the tagged vlans
    # represented in OCTET-STRINGS, maybe already
    # translated to hex by Net::SNMP

    my $vlans_1k = $session->{$prefix}{VlansEnabled1k}{$if_idx};
    my $vlans_2k = $session->{$prefix}{VlansEnabled2k}{$if_idx};
    my $vlans_3k = $session->{$prefix}{VlansEnabled3k}{$if_idx};
    my $vlans_4k = $session->{$prefix}{VlansEnabled4k}{$if_idx};

    # It's importend that the returned SNMP OCTET-STRINGs
    # were untranslated by Net::SNMP!
    # If already translated, we must convert it back to a
    # pure OCTET-STRING and fill it with zeroes to a
    # length of 128-OCTETS = 1024-BITS

    my $vlans_1k_octets = hex2octet($vlans_1k) ^ $zeroes_1k;
    my $vlans_2k_octets = hex2octet($vlans_2k) ^ $zeroes_1k;
    my $vlans_3k_octets = hex2octet($vlans_3k) ^ $zeroes_1k;
    my $vlans_4k_octets = hex2octet($vlans_4k) ^ $zeroes_1k;

    # unpack it into a bit-string

    my $vlans_1k_bits = unpack( 'B*', $vlans_1k_octets );
    my $vlans_2k_bits = unpack( 'B*', $vlans_2k_octets );
    my $vlans_3k_bits = unpack( 'B*', $vlans_3k_octets );
    my $vlans_4k_bits = unpack( 'B*', $vlans_4k_octets );

    $session->{$prefix}{VlansEnabled}{$if_idx} =
      $vlans_1k_bits . $vlans_2k_bits . $vlans_3k_bits . $vlans_4k_bits;

  }
}

# Process tag information for each phys interface
sub _calc_ports2vlans {
  my $session = shift;

  # calculate the tagged vlans for each port

  foreach my $if_idx ( keys %{ $session->{$prefix}{VlansEnabled} } ) {

    # preset with empty arrayref
    $session->{$prefix}{ports2vlans}{$if_idx} = []
      unless exists $session->{$prefix}{ports2vlans}{$if_idx};

    foreach my $vlan_id ( keys %{ $session->{$prefix}{VlanName} } ) {

      if (
        substr( $session->{$prefix}{VlansEnabled}{$if_idx}, $vlan_id, 1 ) eq
        1 )
      {
        push @{ $session->{$prefix}{ports2vlans}{$if_idx} }, $vlan_id;
      }

    }
  }
}

# Process tag information for each phys interface
sub _calc_vlans2ports {
  my $session = shift;

  # calculate the tagged ports for each vlan

  foreach my $if_idx ( keys %{ $session->{$prefix}{VlansEnabled} } ) {

    foreach my $vlan_id ( keys %{ $session->{$prefix}{VlanName} } ) {

      # preset with empty arrayref
      $session->{$prefix}{vlans2ports}{$vlan_id} = []
        unless exists $session->{$prefix}{vlans2ports}{$vlan_id};

      if (
        substr( $session->{$prefix}{VlansEnabled}{$if_idx}, $vlan_id, 1 ) eq
        1 )
      {
        push @{ $session->{$prefix}{vlans2ports}{$vlan_id} }, $if_idx;
      }

    }
  }
}

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a bug or are experiencing difficulties that are not explained within the POD documentation, please submit a bug to the RT system (see link below). However, it would help greatly if you are able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not be forthcoming, please feel free to (politely) remind me by sending an email to gaissmai@cpan.org .

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin-CiscoDot1qVlanStaticTrunks

=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2011-2020 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

unless ( caller() ) {
  print "$prefix compiles and initializes successful.\n";
}

1;

# vim: sw=2
