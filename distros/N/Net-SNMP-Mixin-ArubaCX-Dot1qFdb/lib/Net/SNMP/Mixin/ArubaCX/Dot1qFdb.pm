package Net::SNMP::Mixin::ArubaCX::Dot1qFdb;

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
  @mixin_methods = (qw/ get_dot1q_fdb_entries /);
}

use Sub::Exporter -setup => {
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods], },
};

#
# SNMP oid constants used in this module
#
use constant {
  DOT1Q_TP_FDB_TABLE  => '1.3.6.1.2.1.17.7.1.2.2',
  DOT1Q_TP_FDB_PORT   => '1.3.6.1.2.1.17.7.1.2.2.1.2',
  DOT1Q_TP_FDB_STATUS => '1.3.6.1.2.1.17.7.1.2.2.1.3',

};

=head1 NAME

Net::SNMP::Mixin::ArubaCX::Dot1qFdb - mixin class for ArubaCX switch forwarding databases

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin;

  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );
  $session->mixer('Net::SNMP::Mixin::ArubaCX::Dot1qFdb');
  $session->init_mixins();
  snmp_dispatcher()   if $session->nonblocking;
  $session->init_ok();
  die $session->errors if $session->errors;

  foreach my $fdb_entry ( $session->get_dot1q_fdb_entries() ) {
    my $mac     = $fdb_entry->{MacAddress};
    my $vlan_id = $fdb_entry->{vlanId};
    my $port    = $fdb_entry->{dot1dBasePort};
    my $status  = $fdb_entry->{fdbStatus};

    print "$mac, $vlan_id, $port, $status\n";
  }

=head1 DESCRIPTION

A Net::SNMP mixin class for forwarding database info of ArubaCX 802.1-Q limited MIBs.

=head1 MIXIN METHODS

=head2 B<< @fdb = OBJ->get_dot1q_fdb_entries() >>

Returns a list of fdb entries. Every list element is a reference to a hash with the following fields and values:

    {
      MacAddress      => 'XX:XX:XX:XX:XX:XX',
      dot1dBasePort   => Integer,
      vlanId          => Integer,
      fdbStatus       => Integer,
      fdbStatusString => String,
    }

=over

=item MacAddress

MacAddress received, in normalized IEEE form XX:XX:XX:XX:XX:XX.

=item dot1dBasePort

The receiving bride-port for the MAC address.

=item vlanId

Every MacAdress is related to a distinct vlanId.

=item fdbStatus

The status of this entry. The meanings of the values are:

    1 = other
    2 = invalid
    3 = learned
    4 = self
    5 = mgmt

For more information please see the corresponding Q-BRIDGE-MIB.

=item fdbStatusString

The status of this entry in string form, see above.

=back

=cut

sub get_dot1q_fdb_entries {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  #
  # the port's current state translation table
  #
  my %fdp_entry_status_enum = (
    1 => 'other',
    2 => 'invalid',
    3 => 'learned',
    4 => 'self',
    5 => 'mgmt',
  );

  # stash for return values
  my @fdb_entries = ();

  my ( @digits, $vlan_id, $mac, $mac_string, $port, $status, $status_string );

  # index is VlanId.MacAddress
  foreach my $idx ( keys %{ $session->{$prefix}{dot1qTpFdbPort} } ) {
    $port   = $session->{$prefix}{dot1qTpFdbPort}{$idx};
    $status = $session->{$prefix}{dot1qTpFdbStatus}{$idx};

    # the snmp get_table() isn't a snapshot, it can be, that
    # the MAC has already timeout in the FDB when the
    # status is fetched
    next unless defined $port && defined $status;

    $status_string = $fdp_entry_status_enum{$status};

    # split the idx to vlan_id and mac address
    # index is VlanId.MacAddress, value is the bridge port
    @digits = split /\./, $idx;

    $vlan_id = $digits[0];

    $mac        = pack( 'C6', @digits[ 1 .. 6 ] );
    $mac_string = normalize_mac($mac);

    push @fdb_entries,
      {
      dot1dBasePort   => $port,
      MacAddress      => $mac_string,
      vlanId          => $vlan_id,
      fdbStatus       => $status,
      fdbStatusString => $status_string,
      };
  }

  return @fdb_entries;
}

=head1 INITIALIZATION

=cut

=head2 B<< OBJ->_init($reload) >>

Fetch the fdb related snmp values from the host. Don't call this method direct!

=cut

#
# due to the asynchron nature, we don't know what init job is really the last, we decrement
# the value after each callback
#
use constant THIS_INIT_JOBS => 1;

sub _init {
  my ( $session, $reload ) = @_;
  my $agent = $session->hostname;

  die "$agent: $prefix already initialized and reload not forced.\n"
    if exists get_init_slot($session)->{$prefix}
    && get_init_slot($session)->{$prefix} == 0
    && not $reload;

  # set number of async init jobs for proper initialization
  get_init_slot($session)->{$prefix} = THIS_INIT_JOBS;

  _fetch_dot1q_tp_fdb_entries($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_dot1q_tp_fdb_table() >>

Fetch the forwarding databases from the dot1qTpFdbTable once during object initialization.

=cut

sub _fetch_dot1q_tp_fdb_entries() {
  my $session = shift;
  my $result;

  # fetch the forwarding databases from dot1qTpFdbTable
  $result = $session->get_entries(
    -columns => [ DOT1Q_TP_FDB_PORT, DOT1Q_TP_FDB_STATUS ],

    # define callback if in nonblocking mode
    $session->nonblocking
    ? ( -callback => \&_dot1q_tp_fdb_entries_cb )
    : (),
  );

  unless ( defined $result ) {
    my $err_msg = $session->{_error} = $session->error;
    push_error( $session, "$prefix: $err_msg" ) if $err_msg;
    return;
  }

  return 1 if $session->nonblocking;

  # call the callback function in blocking mode by hand
  _dot1q_tp_fdb_entries_cb($session);

}

sub _dot1q_tp_fdb_entries_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if ( my $err_msg = $session->{_error} = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # mangle result table to get plain idx->value
  # index is fdbId.MacAddress, value is the bridge port
  $session->{$prefix}{dot1qTpFdbPort} = idx2val( $vbl, DOT1Q_TP_FDB_PORT );

  # mangle result table to get plain idx->value
  # index is fdbId.MacAddress, value is the entry status
  $session->{$prefix}{dot1qTpFdbStatus} = idx2val( $vbl, DOT1Q_TP_FDB_STATUS );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

=head1 SEE ALSO

L<< Net::SNMP::Mixin::Dot1dBase >> for a mapping between ifIndexes and bridgePorts.

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 AUTHOR

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
