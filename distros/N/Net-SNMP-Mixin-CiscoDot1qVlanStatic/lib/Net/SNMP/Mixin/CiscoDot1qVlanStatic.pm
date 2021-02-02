package Net::SNMP::Mixin::CiscoDot1qVlanStatic;

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
  @mixin_methods = qw/
    map_vlan_id2name
    map_vlan_id2if_idx
    map_if_idx2vlan_id
    /;
}

use Sub::Exporter -setup => {
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods], },
};

#
# SNMP oid constants from CISCO-VTP-MIB and CISCO-VLAN-MEMBERSHIP-MIB
#
use constant {
  ###
  # trunk ports: CISCO-VTP-MIB
  VLAN_TBL   => '1.3.6.1.4.1.9.9.46.1.3.1',
  VLAN_STATE => '1.3.6.1.4.1.9.9.46.1.3.1.1.2',
  VLAN_NAME  => '1.3.6.1.4.1.9.9.46.1.3.1.1.4',

  VLAN_TRUNK_PORT_TBL              => '1.3.6.1.4.1.9.9.46.1.6.1',
  VLAN_TRUNK_PORT_VLANS_ENABLED_1K => '1.3.6.1.4.1.9.9.46.1.6.1.1.4',
  VLAN_TRUNK_PORT_NATIVE_VLAN      => '1.3.6.1.4.1.9.9.46.1.6.1.1.5',
  VLAN_TRUNK_PORT_ENCAPS_OPER_TYPE => '1.3.6.1.4.1.9.9.46.1.6.1.1.16',
  VLAN_TRUNK_PORT_VLANS_ENABLED_2K => '1.3.6.1.4.1.9.9.46.1.6.1.1.17',
  VLAN_TRUNK_PORT_VLANS_ENABLED_3K => '1.3.6.1.4.1.9.9.46.1.6.1.1.18',
  VLAN_TRUNK_PORT_VLANS_ENABLED_4K => '1.3.6.1.4.1.9.9.46.1.6.1.1.19',

  ###
  # access ports: CISCO-VLAN-MEMBERSHIP-MIB
  # table maybe empty!
  #
  # "A table for configuring VLAN port membership.
  # There is one row for each bridge port that is
  # assigned to a static or dynamic access port. Trunk
  # ports are not  represented in this table.  An entry
  # may be created and deleted when ports are created or
  # deleted via SNMP or the management console on a
  # device."

  VM_MEMBERSHIP_TABLE => '1.3.6.1.4.1.9.9.68.1.2.2',
  VM_VLAN_TYPE        => '1.3.6.1.4.1.9.9.68.1.2.2.1.1',
  VM_VLAN             => '1.3.6.1.4.1.9.9.68.1.2.2.1.2',
};

=head1 NAME

Net::SNMP::Mixin::CiscoDot1qVlanStatic - mixin class for static Cisco vlan info

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin;

  # initialize session and mixin library
  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );
  $session->mixer('Net::SNMP::Mixin::CiscoDot1qVlanStatic');
  $session->init_mixins;
  snmp_dispatcher();
  $session->init_ok();
  die $session->errors if $session->errors;

  # show VLAN IDs and corresponding names
  my $id2name = $session - map_vlan_id2name();
  foreach my $id ( keys %{$id2name} ) {
    printf "Vlan-Id: %4d  => Vlan-Name: %s\n", $id, $id2name->{$id};
  }

  # sorted by vlan_id
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

A mixin class for vlan related infos from the CISCO-VTP-MIB for 802.1Q-trunks and
CISCO-VLAN-MEMBERSHIP-MIB for access ports.
The mixin-module provides methods for mapping between vlan-ids and vlan-names und relations between
interfaces and vlan-ids, tagged or untagged on these ports.

=head1 MIXIN METHODS

=head2 B<< OBJ->map_vlan_id2name() >>

Returns a hash reference with vlan-ids as keys and the corresponding vlan-names as values:

  {
    vlan_id => vlan_name,
    vlan_id => vlan_name,
    ... ,
  }

=cut

sub map_vlan_id2name {
  my $session = shift;
  Carp::croak "'$prefix' not initialized,"
    unless $session->{$prefix}{__initialized};

  return $session->{$prefix}{vlan_id2name};
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
  Carp::croak "'$prefix' not initialized,"
    unless $session->{$prefix}{__initialized};

  return _get_vlan_ids2if_idx($session);
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
  Carp::croak "'$prefix' not initialized,"
    unless $session->{$prefix}{__initialized};

  return _get_if_idx2vlan_ids($session);
}

=head1 INITIALIZATION

=head2 B<< OBJ->_init($reload) >>

Fetch basic Vlan related SNMP values from the host. Don't call this method direct!

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

  # initialize the object for vtp vlan table
  _fetch_vtp_vlan_tbl_entries($session);
  return if $session->error;

  # initialize the object for vtp vlan trunk port table for trunk ports
  _fetch_vtp_vlan_trunk_port_tbl_entries($session);
  return if $session->error;

  # initialize the object for vlan membership table of access ports
  _fetch_vm_membership_tbl_entries($session);
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

  # fetch the vlan state and name from vlanTable
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

  unless ( defined $result ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # in nonblocking mode the callback will be called asynchronously
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

  unless ( defined $vbl ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # mangle result table to get plain
  # 	VlanIndex => vlan-state
  #
  $session->{$prefix}{_VlanState} = idx2val( $vbl, VLAN_STATE, 1 );

  # mangle result table to get plain
  # 	VlanIndex => vlan-name
  #
  $session->{$prefix}{vlan_id2name} = idx2val( $vbl, VLAN_NAME, 1 );

  # purge non operational vlans, see CISCO-VTP-MIB
  foreach my $vlan_id ( keys %{ $session->{$prefix}{vlan_id2name} } ) {
    delete $session->{$prefix}{vlan_id2name}{$vlan_id}
      unless $session->{$prefix}{_VlanState}{$vlan_id} == 1;
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
      VLAN_TRUNK_PORT_ENCAPS_OPER_TYPE,
      VLAN_TRUNK_PORT_NATIVE_VLAN,

      VLAN_TRUNK_PORT_VLANS_ENABLED_1K,
      VLAN_TRUNK_PORT_VLANS_ENABLED_2K,
      VLAN_TRUNK_PORT_VLANS_ENABLED_3K,
      VLAN_TRUNK_PORT_VLANS_ENABLED_4K,
    ],

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_vtp_vlan_trunk_port_tbl_entries_cb ) : (),

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
  _vtp_vlan_trunk_port_tbl_entries_cb($session);

}

=head2 B<< _vtp_vlan_trunk_port_tbl_entries_cb($session) >>

The callback for _fetch_vtp_vlan_trunk_port_tbl_entries.

=cut

sub _vtp_vlan_trunk_port_tbl_entries_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # mangle result table to get plain
  # 	ifIndex => vlans-enabled-bitstring
  #
  $session->{$prefix}{_VlansEnabled1k} =
    idx2val( $vbl, VLAN_TRUNK_PORT_VLANS_ENABLED_1K, );

  $session->{$prefix}{_VlansEnabled2k} =
    idx2val( $vbl, VLAN_TRUNK_PORT_VLANS_ENABLED_2K, );

  $session->{$prefix}{_VlansEnabled3k} =
    idx2val( $vbl, VLAN_TRUNK_PORT_VLANS_ENABLED_3K, );

  $session->{$prefix}{_VlansEnabled4k} =
    idx2val( $vbl, VLAN_TRUNK_PORT_VLANS_ENABLED_4K, );

  $session->{$prefix}{_VlansEncapsOperType} =
    idx2val( $vbl, VLAN_TRUNK_PORT_ENCAPS_OPER_TYPE, );

  $session->{$prefix}{NativeVlan} =
    idx2val( $vbl, VLAN_TRUNK_PORT_NATIVE_VLAN, );

  $session->{$prefix}{__initialized}++;

  _calc_tagged_ports($session);

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

sub _calc_tagged_ports {
  my $session = shift;

  # prepare fillmask, see below
  my $zeroes_1k = pack( 'B*', 0 x 1024 );

  # iterate over any hash to get the interfaces as keys
  foreach my $if_idx ( keys %{ $session->{$prefix}{NativeVlan} } ) {

    # only dot1Q(4) is supported, see CISCO-VTP-MIB
    if ( $session->{$prefix}{_VlansEncapsOperType}{$if_idx} != 4 ) {
      $session->{$prefix}{TaggedVlans}{$if_idx} = undef;
      next;
    }

    # for all phys interfaces get the tagged vlans
    # represented in OCTET-STRINGS

    my $vlans_1k = $session->{$prefix}{_VlansEnabled1k}{$if_idx};
    my $vlans_2k = $session->{$prefix}{_VlansEnabled2k}{$if_idx};
    my $vlans_3k = $session->{$prefix}{_VlansEnabled3k}{$if_idx};
    my $vlans_4k = $session->{$prefix}{_VlansEnabled4k}{$if_idx};

    # It's important that the returned SNMP OCTET-STRINGs were untranslated by Net::SNMP!
    # If already translated, we must convert it back to a pure OCTET-STRING
    # and fill it with zeroes to a length of 128-OCTETS = 1024-BITS

    my $vlans_1k_octets = hex2octet($vlans_1k) ^ $zeroes_1k;
    my $vlans_2k_octets = hex2octet($vlans_2k) ^ $zeroes_1k;
    my $vlans_3k_octets = hex2octet($vlans_3k) ^ $zeroes_1k;
    my $vlans_4k_octets = hex2octet($vlans_4k) ^ $zeroes_1k;

    # unpack it into a bit-string
    my $vlans_1k_bits = unpack( 'B*', $vlans_1k_octets );
    my $vlans_2k_bits = unpack( 'B*', $vlans_2k_octets );
    my $vlans_3k_bits = unpack( 'B*', $vlans_3k_octets );
    my $vlans_4k_bits = unpack( 'B*', $vlans_4k_octets );

    # concat all 4k possible vlan_ids as bitstring
    $session->{$prefix}{TaggedVlans}{$if_idx} =
      $vlans_1k_bits . $vlans_2k_bits . $vlans_3k_bits . $vlans_4k_bits;
  }

}

=head2 B<< _fetch_vm_membership_tbl_entries($session) >>

Fetch selected rows from vmMembershipTable during object initialization.
The table maybe empty if there is no switch port in access mode.

=cut

sub _fetch_vm_membership_tbl_entries {
  my $session = shift;
  my $result;

  # fetch selected entries from vmMembershipTable
  $result = $session->get_entries(
    -columns => [ VM_VLAN_TYPE, VM_VLAN ],

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_vm_membership_tbl_entries_cb ) : (),

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
  _vm_membership_tbl_entries_cb($session);

}

=head2 B<< _vm_membership_tbl_entries_cb($session) >>

The callback for _fetch_vm_membership_tbl_entries.

=cut

sub _vm_membership_tbl_entries_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    my $err_msg = $session->error // '';

    if ( $err_msg !~ m/The requested entries are empty or do not exist/i ) {
      push_error( $session, "$prefix: $err_msg" ) if defined $err_msg;
    }
    else {
      # the table maybe empty if the device has no access ports
      $session->{$prefix}{AccessVlan} = {};

      # this init slot is finished even if table is empty!
      get_init_slot($session)->{$prefix}--;
    }

    return;
  }

  # mangle result table to get plain
  # 	ifIndex => values
  #
  $session->{$prefix}{_VlanType} =
    idx2val( $vbl, VM_VLAN_TYPE, );

  $session->{$prefix}{_VlanId} =
    idx2val( $vbl, VM_VLAN, );

  foreach my $if_idx ( keys %{ $session->{$prefix}{_VlanType} } ) {

    # only static(1) vlans are supported, see CISCO-VLAN-MEMBERSHIP-MIB
    next if $session->{$prefix}{_VlanType}{$if_idx} != 1;

    $session->{$prefix}{AccessVlan}{$if_idx} = $session->{$prefix}{_VlanId}{$if_idx};
  }

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

# Process tagged/untagged ports for each vlan
sub _get_vlan_ids2if_idx {
  my $session = shift;

  my $result;
  foreach my $vlan_id ( sort keys %{ $session->{$prefix}{vlan_id2name} } ) {
    $result->{$vlan_id}{tagged}   = [];
    $result->{$vlan_id}{untagged} = [];

    # iterate over any hash from VTP table to get all interfaces
    foreach my $if_idx ( sort keys %{ $session->{$prefix}{NativeVlan} } ) {

      # access ports
      if ( my $access_vlan = $session->{$prefix}{AccessVlan}{$if_idx} ) {
        push( @{ $result->{$vlan_id}{untagged} }, $if_idx ) if $access_vlan == $vlan_id;

        # next interface
        next;
      }

      # trunk ports
      next unless defined $session->{$prefix}{TaggedVlans}{$if_idx};

      if ( substr( $session->{$prefix}{TaggedVlans}{$if_idx}, $vlan_id, 1 ) eq 1 ) {
        if ( $session->{$prefix}{NativeVlan}{$if_idx} != $vlan_id ) {

          # ... and it's not the native vlan of this trunk
          push @{ $result->{$vlan_id}{tagged} }, $if_idx;
        }
        else {
          # ... it's the native vlan of this trunk
          push @{ $result->{$vlan_id}{untagged} }, $if_idx;
        }
      }
    }
  }

  return $result;
}

# Process tagged/untagged vlans for each interface
#
# reverse datastructure vlan_ids to ports  ==> ports to vlan ids
#
# FROM:
# vlan_id => {
#      tagged   => [if_idx, ..., ],
#      untagged => [if_idx, ..., ],
#    },
#
# TO:
#    if_idx => {
#      tagged   => [vlan_id, ..., ],
#      untagged => [vlan_id, ..., ],
#    },
#
sub _get_if_idx2vlan_ids {
  my $vlan_ids2if_idx = _get_vlan_ids2if_idx(shift);

  my $result;
  foreach my $vlan_id ( keys %$vlan_ids2if_idx ) {
    foreach my $if_idx ( @{ $vlan_ids2if_idx->{$vlan_id}{tagged} } ) {
      push @{ $result->{$if_idx}{tagged} }, $vlan_id;
    }
    foreach my $if_idx ( @{ $vlan_ids2if_idx->{$vlan_id}{untagged} } ) {
      push @{ $result->{$if_idx}{untagged} }, $vlan_id;
    }
  }
  return $result;
}

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2020-2021 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

unless ( caller() ) {
  print "$prefix compiles and initializes successful.\n";
}

1;

# vim: sw=2
