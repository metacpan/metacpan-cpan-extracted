package Net::SNMP::Mixin::InetCidrRouteTable;

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
use Net::SNMP qw(oid_lex_sort);
use Net::SNMP::Mixin::Util qw/idx2val push_error get_init_slot/;
use Socket qw(inet_ntop AF_INET AF_INET6);

#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (qw/ get_inet_cidr_route_table /);
}

use Sub::Exporter -setup => {
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods], },
};

=head1 NAME

Net::SNMP::Mixin::InetCidrRouteTable - mixin class for the inetCidrRouteTable

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin;

  #...

  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );

  $session->mixer('Net::SNMP::Mixin::InetCidrRouteTable');
  $session->init_mixins;
  snmp_dispatcher();
  $session->init_ok();
  die $session->errors if $session->errors;

  my @routes = $session->get_inet_cidr_route_table();

  foreach my $route (@routes) {
    my $prefix   = $route->{inetCidrRoutePrefix};
    my $next_hop = $route->{inetCidrRouteNextHop};
    my $if_index = $route->{inetCidrRouteIfIndex};
    # ...

    print "$prefix => $if_index/$next_hop\n";
  }

=head1 DESCRIPTION

A Net::SNMP mixin class for inetCidrRouteTable.

The inetCidrRouteTable provides the ability to display IP version-independent multipath CIDR routes.

=cut

#
# SNMP oid constants used in this module
#
# from IP Forwarding Table MIB, RFC 2096
#
use constant {
  INET_CIDR_ROUTE_TABLE => '1.3.6.1.2.1.4.24.7',
  INET_CIDR_ROUTE_ENTRY => '1.3.6.1.2.1.4.24.7.1',

  INET_CIDR_ROUTE_DEST_TYPE    => '1.3.6.1.2.1.4.24.7.1.1',    # index, InetAddressType
  INET_CIDR_ROUTE_DEST         => '1.3.6.1.2.1.4.24.7.1.2',    # index, InetAddress
  INET_CIDR_ROUTE_PFXLEN       => '1.3.6.1.2.1.4.24.7.1.3',    # index, InetAddressPrefixLength
  INET_CIDR_ROUTE_POLICY       => '1.3.6.1.2.1.4.24.7.1.4',    # index, OID
  INET_CIDR_ROUTE_NEXTHOP_TYPE => '1.3.6.1.2.1.4.24.7.1.5',    # index, InetAddressType
  INET_CIDR_ROUTE_NEXTHOP      => '1.3.6.1.2.1.4.24.7.1.6',    # index, InetAddress
  INET_CIDR_ROUTE_IFINDEX      => '1.3.6.1.2.1.4.24.7.1.7',
  INET_CIDR_ROUTE_TYPE         => '1.3.6.1.2.1.4.24.7.1.8',
  INET_CIDR_ROUTE_PROTO        => '1.3.6.1.2.1.4.24.7.1.9',
  INET_CIDR_ROUTE_AGE          => '1.3.6.1.2.1.4.24.7.1.10',
  INET_CIDR_ROUTE_NEXTHOPAS    => '1.3.6.1.2.1.4.24.7.1.11',
  INET_CIDR_ROUTE_METRIC1      => '1.3.6.1.2.1.4.24.7.1.12',
  INET_CIDR_ROUTE_METRIC2      => '1.3.6.1.2.1.4.24.7.1.13',
  INET_CIDR_ROUTE_METRIC3      => '1.3.6.1.2.1.4.24.7.1.14',
  INET_CIDR_ROUTE_METRIC4      => '1.3.6.1.2.1.4.24.7.1.15',
  INET_CIDR_ROUTE_METRIC5      => '1.3.6.1.2.1.4.24.7.1.16',
  INET_CIDR_ROUTE_STATUS       => '1.3.6.1.2.1.4.24.7.1.17',
};

#
# the InetAddressType enum
#
my %address_type_enum = (
  0  => 'unknown',
  1  => 'ipv4',
  2  => 'ipv6',
  3  => 'ipv4z',
  4  => 'ipv6z',
  16 => 'dns16',
);

#
# the inetCidrRouteType enum
#
my %route_type_enum = (
  1 => 'other',
  2 => 'reject',
  3 => 'local',
  4 => 'remote',
  5 => 'blackhole',
);

#
# the inetCidrRouteProto enum
#
my %proto_enum = (
  1  => 'other',
  2  => 'local',
  3  => 'netmgmt',
  4  => 'icmp',
  5  => 'egp',
  6  => 'ggp',
  7  => 'hello',
  8  => 'rip',
  9  => 'is-is',
  10 => 'es-is',
  11 => 'ciscoIgrp',
  12 => 'bbnSpfIgp',
  13 => 'ospf',
  14 => 'bgp',
  15 => 'idpr',
  16 => 'ciscoEigrp',
  17 => 'DVMR',
  18 => 'RPL',
  19 => 'DHCP',
  20 => 'TTDP',
);

#
# the inetCidrRouteStatus enum
#
my %status_enum = (
  1 => 'active',
  2 => 'notInService',
  3 => 'notReady',
  4 => 'createAndGo',
  5 => 'createAndWait',
  6 => 'destroy',
);

=head1 MIXIN METHODS

=head2 B<< OBJ->get_inet_cidr_route_table() >>

Returns a sorted list of inetCidrRouteTable and cooked entries. Every list element (route entry) is a hashref with the following fields and values:

    {
        inetCidrRoutePrefix       => CIDR String,
        inetCidrRouteZone         => InetAddress,
	inetCidrRouteNextHop      => InetAddress,
        inetCidrRoutePolicy       => OBJECT IDENTIFIER,
        inetCidrRouteIfIndex      => InterfaceIndexOrZero,
        inetCidrRouteType         => INTEGER,
        inetCidrRouteTypeString   => String,                    # resolved enum
        inetCidrRouteProto        => IANAipRouteProtocol,
        inetCidrRouteProtoString  => String,                    # resolved enum
        inetCidrRouteAge          => Gauge32,
        inetCidrRouteNextHopAS    => InetAutonomousSystemNumber,
        inetCidrRouteMetric1      => Integer32,
        inetCidrRouteMetric2      => Integer32,
        inetCidrRouteMetric3      => Integer32,
        inetCidrRouteMetric4      => Integer32,
        inetCidrRouteMetric5      => Integer32,
        inetCidrRouteStatus       => RowStatus
        inetCidrRouteStatusString => String,                    # resolved enum
    }

=cut

sub get_inet_cidr_route_table {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # stash for return values
  my @route_tbl;

  my (
    $inetCidrRoutePrefix,      $inetCidrRouteZone,    $inetCidrRouteNextHop,    $inetCidrRoutePolicy,
    $inetCidrRouteIfIndex,     $inetCidrRouteType,    $inetCidrRouteTypeString, $inetCidrRouteProto,
    $inetCidrRouteProtoString, $inetCidrRouteAge,     $inetCidrRouteNextHopAS,  $inetCidrRouteMetric1,
    $inetCidrRouteMetric2,     $inetCidrRouteMetric3, $inetCidrRouteMetric4,    $inetCidrRouteMetric5,
    $inetCidrRouteStatus,      $inetCidrRouteStatusString,
  );

  #
  # inetCidrRouteIfIndex is used for table index walk
  foreach my $idx ( oid_lex_sort keys %{ $session->{$prefix}{inetCidrRouteIfIndex} } ) {

    $inetCidrRoutePrefix       = $session->{$prefix}{inetCidrRoutePrefix}{$idx} // '';
    $inetCidrRouteZone         = $session->{$prefix}{inetCidrRouteZone}{$idx} // '';
    $inetCidrRouteNextHop      = $session->{$prefix}{inetCidrRouteNextHop}{$idx} // '';
    $inetCidrRoutePolicy       = $session->{$prefix}{inetCidrRoutePolicy}{$idx} // '';
    $inetCidrRouteIfIndex      = $session->{$prefix}{inetCidrRouteIfIndex}{$idx} // 0;
    $inetCidrRouteType         = $session->{$prefix}{inetCidrRouteType}{$idx} // -1;
    $inetCidrRouteTypeString   = $route_type_enum{$inetCidrRouteType} // 'unknown';
    $inetCidrRouteProto        = $session->{$prefix}{inetCidrRouteProto}{$idx} // -1;
    $inetCidrRouteProtoString  = $proto_enum{$inetCidrRouteProto} // 'unknown';
    $inetCidrRouteAge          = $session->{$prefix}{inetCidrRouteAge}{$idx};
    $inetCidrRouteNextHopAS    = $session->{$prefix}{inetCidrRouteNextHopAS}{$idx};
    $inetCidrRouteMetric1      = $session->{$prefix}{inetCidrRouteMetric1}{$idx};
    $inetCidrRouteMetric2      = $session->{$prefix}{inetCidrRouteMetric2}{$idx};
    $inetCidrRouteMetric3      = $session->{$prefix}{inetCidrRouteMetric3}{$idx};
    $inetCidrRouteMetric4      = $session->{$prefix}{inetCidrRouteMetric4}{$idx};
    $inetCidrRouteMetric5      = $session->{$prefix}{inetCidrRouteMetric5}{$idx};
    $inetCidrRouteStatus       = $session->{$prefix}{inetCidrRouteStatus}{$idx} // -1;
    $inetCidrRouteStatusString = $status_enum{$inetCidrRouteStatus} // 'unknown';

    push @route_tbl, {
      inetCidrRoutePrefix       => $inetCidrRoutePrefix,
      inetCidrRouteZone         => $inetCidrRouteZone,
      inetCidrRouteNextHop      => $inetCidrRouteNextHop,
      inetCidrRoutePolicy       => $inetCidrRoutePolicy,
      inetCidrRouteIfIndex      => $inetCidrRouteIfIndex,
      inetCidrRouteType         => $inetCidrRouteType,
      inetCidrRouteTypeString   => $inetCidrRouteTypeString,
      inetCidrRouteProto        => $inetCidrRouteProto,
      inetCidrRouteProtoString  => $inetCidrRouteProtoString,
      inetCidrRouteAge          => $inetCidrRouteAge,
      inetCidrRouteNextHopAS    => $inetCidrRouteNextHopAS,
      inetCidrRouteMetric1      => $inetCidrRouteMetric1,
      inetCidrRouteMetric2      => $inetCidrRouteMetric2,
      inetCidrRouteMetric3      => $inetCidrRouteMetric3,
      inetCidrRouteMetric4      => $inetCidrRouteMetric4,
      inetCidrRouteMetric5      => $inetCidrRouteMetric5,
      inetCidrRouteStatus       => $inetCidrRouteStatus,
      inetCidrRouteStatusString => $inetCidrRouteStatusString,

    };
  }

  return @route_tbl;
}

=head1 INITIALIZATION

=head2 B<< OBJ->_init($reload) >>

Fetch the inetCidrRouteTable from the host. Don't call this method direct!

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

  # populate the object with needed mib values
  #
  # initialize the object for inetCidrRouteTable infos
  _fetch_inet_cidr_route_tbl($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_inet_cidr_route_tbl($session) >>

Fetch the inetCidrRouteTable once during object initialization.

=cut

sub _fetch_inet_cidr_route_tbl {
  my $session = shift;
  my $result;

  # fetch the inetCidrRouteTable
  $result = $session->get_table(
    -baseoid => INET_CIDR_ROUTE_TABLE,

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_inet_cidr_route_tbl_cb ) : (),

  );

  unless ( defined $result ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # in nonblocking mode the callback will be called asynchronously
  return 1 if $session->nonblocking;

  # ok we are in synchronous mode, call the result mangling function
  # by hand
  _inet_cidr_route_tbl_cb($session);

}

=head2 B<< _inet_cidr_route_tbl_cb($session) >>

The callback for _fetch_inet_cidr_route_tbl().

=cut

sub _inet_cidr_route_tbl_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if ( my $err_msg = $session->error ) {
      push_error( $session, "$prefix: $err_msg" );
    }
    return;
  }

  # build parallel hashes, keys are the very complex table index,
  # index OIDs are not extra populated with valus,
  #
  # INET_CIDR_ROUTE_DEST_TYPE    => '1.3.6.1.2.1.4.24.7.1.1',    # index, InetAddressType
  # INET_CIDR_ROUTE_DEST         => '1.3.6.1.2.1.4.24.7.1.2',    # index, InetAddress
  # INET_CIDR_ROUTE_PFXLEN       => '1.3.6.1.2.1.4.24.7.1.3',    # index, InetAddressPrefixLength
  # INET_CIDR_ROUTE_POLICY       => '1.3.6.1.2.1.4.24.7.1.4',    # index, OID
  # INET_CIDR_ROUTE_NEXTHOP_TYPE => '1.3.6.1.2.1.4.24.7.1.5',    # index, InetAddressType
  # INET_CIDR_ROUTE_NEXTHOP      => '1.3.6.1.2.1.4.24.7.1.6',    # index, InetAddress
  #
  # split the index for these values in get_inet_cidr_route_table()
  #

  $session->{$prefix}{inetCidrRouteIfIndex} =
    idx2val( $vbl, INET_CIDR_ROUTE_IFINDEX, undef, undef, );

  $session->{$prefix}{inetCidrRouteType} =
    idx2val( $vbl, INET_CIDR_ROUTE_TYPE, undef, undef, );

  $session->{$prefix}{inetCidrRouteProto} =
    idx2val( $vbl, INET_CIDR_ROUTE_PROTO, undef, undef, );

  $session->{$prefix}{inetCidrRouteAge} =
    idx2val( $vbl, INET_CIDR_ROUTE_AGE, undef, undef, );

  $session->{$prefix}{inetCidrRouteNextHopAS} =
    idx2val( $vbl, INET_CIDR_ROUTE_NEXTHOPAS, undef, undef, );

  $session->{$prefix}{inetCidrRouteMetric1} =
    idx2val( $vbl, INET_CIDR_ROUTE_METRIC1, undef, undef, );

  $session->{$prefix}{inetCidrRouteMetric2} =
    idx2val( $vbl, INET_CIDR_ROUTE_METRIC2, undef, undef, );

  $session->{$prefix}{inetCidrRouteMetric3} =
    idx2val( $vbl, INET_CIDR_ROUTE_METRIC3, undef, undef, );

  $session->{$prefix}{inetCidrRouteMetric4} =
    idx2val( $vbl, INET_CIDR_ROUTE_METRIC4, undef, undef, );

  $session->{$prefix}{inetCidrRouteMetric5} =
    idx2val( $vbl, INET_CIDR_ROUTE_METRIC5, undef, undef, );

  $session->{$prefix}{inetCidrRouteStatus} =
    idx2val( $vbl, INET_CIDR_ROUTE_STATUS, undef, undef, );

  foreach my $idx ( keys %{ $session->{$prefix}{inetCidrRouteIfIndex} } ) {

    #
    # split the index for these values to get the values for prefix, next_hop and policy
    #
    my ( $rt_prefix, $zone, $next_hop, $policy ) = _split_idx( $session, $idx );

    $session->{$prefix}{inetCidrRoutePrefix}{$idx}  = $rt_prefix;
    $session->{$prefix}{inetCidrRouteZone}{$idx}    = $zone;
    $session->{$prefix}{inetCidrRouteNextHop}{$idx} = $next_hop;
    $session->{$prefix}{inetCidrRoutePolicy}{$idx}  = $policy;
  }

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
}

# type IPv4
# | len in bytes
# | | IP address destination, var len
# | | |         Pfxlen destination
# | | |         |  OID, policy, var len
# | | |         |  |     type
# | | |         |  |     | len in bytes
# | | |         |  |     | | IP address next hop, var len
# | | |         |  |     | | |
# 1.4.10.96.2.0.24.2.0.0.1.4.134.60.112.246

# type IPv6
# | len in bytes
# | |  IP address destination, var len
# | |  |                                     Pfxlen destination
# | |  |                                     |   OID, policy, var len
# | |  |                                     |   |     type
# | |  |                                     |   |     | len in bytes
# | |  |                                     |   |     | |  IP address next hop, var len
# | |  |                                     |   |     | |  |
# 2.16.32.1.7.192.0.3.161.11.0.0.0.0.0.0.0.0.127.2.0.0.2.16.254.128.0.0.0.0.0.0.78.119.109.255.254.212.255.135

# type IPv6z
# | len in bytes
# | |  IP address destination, var len
# | |  |                                            Pfxlen destination
# | |  |                                            |  OID, policy, var len
# | |  |                                            |  |     type
# | |  |                                            |  |     | len in bytes
# | |  |                                            |  |     | |
# | |  |                                            |  |     | |
# 4.20.254.128.0.0.0.0.0.0.0.0.0.0.0.0.0.0.18.0.0.1.10.2.0.0.0.0

sub _split_idx {
  my ( $session, $idx ) = @_;

  my @subs = split( /\./, $idx );

  my ( $t1, $t2, $dest, $nh, $pfx_len, $policy, $size );

  $t1   = shift @subs;
  $size = shift @subs;
  $dest = pack( 'C*', @subs[ 0 .. $size - 1 ] );

  @subs = @subs[ $size .. $#subs ];

  $pfx_len = shift @subs;
  $size    = shift @subs;
  $policy  = join( '.', @subs[ 0 .. $size - 1 ] );

  @subs = @subs[ $size .. $#subs ];

  $t2   = shift @subs;
  $size = shift @subs;
  $nh   = pack( 'C*', @subs[ 0 .. $size - 1 ] );

  my ( $rt_prefix, $zone, $next_hop );

  ( $rt_prefix, $zone ) = _get_addr( $session, $idx, $t1, $dest );
  $rt_prefix = "$rt_prefix/$pfx_len" if defined $rt_prefix;

  ( $next_hop, undef ) = _get_addr( $session, $idx, $t2, $nh );

  return ( $rt_prefix, $zone, $next_hop, $policy );
}

sub _get_addr {
  my ( $session, $idx, $type, $n_bytes ) = @_;

  if ( $address_type_enum{$type} eq 'unknown' ) {
    my $len = do { use bytes; length($n_bytes) };
    push_error( $session, "$prefix: address-type and -value mismatch in '$idx'" )
      if $len != 0;
    return;
  }

  if ( $address_type_enum{$type} eq 'ipv4' ) {
    my $len = do { use bytes; length($n_bytes) };
    push_error( $session, "$prefix: address-type and -value mismatch in '$idx'" )
      if $len != 4;

    my $ip_addr = inet_ntop( AF_INET, $n_bytes );
    return $ip_addr;
  }

  if ( $address_type_enum{$type} eq 'ipv6' ) {
    my $len = do { use bytes; length($n_bytes) };
    push_error( $session, "$prefix: address-type and -value mismatch in '$idx'" )
      if $len != 16;

    my $ip_addr = inet_ntop( AF_INET6, $n_bytes );
    return $ip_addr;
  }

  # addrs with zones suffix
  if ( $address_type_enum{$type} eq 'ipv4z' ) {
    my $len = do { use bytes; length($n_bytes) };
    push_error( $session, "$prefix: address-type and -value mismatch in '$idx'" )
      if $len != 8;

    my $ip_n   = substr( $n_bytes, 0, 4 );
    my $zone_n = substr( $n_bytes, 4, 4 );

    my $ip_addr = inet_ntop( AF_INET, $ip_n );
    my $zone    = inet_ntop( AF_INET, $zone_n );

    return ( $ip_addr, $zone );
  }

  if ( $address_type_enum{$type} eq 'ipv6z' ) {
    my $len = do { use bytes; length($n_bytes) };
    push_error( $session, "$prefix: address-type and -value mismatch in '$idx'" )
      if $len != 20;

    my $ip_n   = substr( $n_bytes, 0,  16 );
    my $zone_n = substr( $n_bytes, 16, 4 );

    my $ip_addr = inet_ntop( AF_INET6, $ip_n );
    my $zone    = inet_ntop( AF_INET,  $zone_n );

    return ( $ip_addr, $zone );
  }

  push_error( $session, "$prefix: unknown address-type '$type' in '$idx'" );
  return;
}

unless ( caller() ) {
  print "$prefix compiles and initializes successful.\n";
}

=head1 SEE ALSO

L<< Net::SNMP::Mixin >>

=head1 REQUIREMENTS

L<< Net::SNMP >>, L<< Net::SNMP::Mixin >>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a bug or are experiencing difficulties that are not explained within the POD documentation, please submit a bug to the RT system (see link below). However, it would help greatly if you are able to pinpoint problems or even supply a patch. 

Fixes are dependant upon their severity and my availablity. Should a fix not be forthcoming, please feel free to (politely) remind me by sending an email to gaissmai@cpan.org .

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin-InetCidrRouteTable


=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2019 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

# vim: sw=2
