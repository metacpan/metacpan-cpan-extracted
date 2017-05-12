package Net::SNMP::Mixin::IpCidrRouteTable;

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

#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (qw/ get_ip_cidr_route_table /);
}

use Sub::Exporter -setup => {
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods], },
};

#
# SNMP oid constants used in this module
#
# from IP Forwarding Table MIB, RFC 2096
#
use constant {
  IP_CIDR_ROUTE_TABLE => '1.3.6.1.2.1.4.24.4',
  IP_CIDR_ROUTE_ENTRY => '1.3.6.1.2.1.4.24.4.1',

  IP_CIDR_ROUTE_DEST      => '1.3.6.1.2.1.4.24.4.1.1',
  IP_CIDR_ROUTE_MASK      => '1.3.6.1.2.1.4.24.4.1.2',
  IP_CIDR_ROUTE_TOS       => '1.3.6.1.2.1.4.24.4.1.3',
  IP_CIDR_ROUTE_NEXTHOP   => '1.3.6.1.2.1.4.24.4.1.4',
  IP_CIDR_ROUTE_IFINDEX   => '1.3.6.1.2.1.4.24.4.1.5',
  IP_CIDR_ROUTE_TYPE      => '1.3.6.1.2.1.4.24.4.1.6',
  IP_CIDR_ROUTE_PROTO     => '1.3.6.1.2.1.4.24.4.1.7',
  IP_CIDR_ROUTE_AGE       => '1.3.6.1.2.1.4.24.4.1.8',
  IP_CIDR_ROUTE_INFO      => '1.3.6.1.2.1.4.24.4.1.9',
  IP_CIDR_ROUTE_NEXTHOPAS => '1.3.6.1.2.1.4.24.4.1.10',
  IP_CIDR_ROUTE_METRIC1   => '1.3.6.1.2.1.4.24.4.1.11',
  IP_CIDR_ROUTE_METRIC2   => '1.3.6.1.2.1.4.24.4.1.12',
  IP_CIDR_ROUTE_METRIC3   => '1.3.6.1.2.1.4.24.4.1.13',
  IP_CIDR_ROUTE_METRIC4   => '1.3.6.1.2.1.4.24.4.1.14',
  IP_CIDR_ROUTE_METRIC5   => '1.3.6.1.2.1.4.24.4.1.15',
  IP_CIDR_ROUTE_STATUS    => '1.3.6.1.2.1.4.24.4.1.16',
};

#
# the ipCidrRouteType enum
#
my %type_enum = (
  1 => 'other',
  2 => 'reject',
  3 => 'local',
  4 => 'remote',
);

#
# the ipCidrRouteProto enum
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
);

#
# the ipCidrRouteStatus enum
#
my %status_enum = (
  1 => 'active',
  2 => 'notInService',
  3 => 'notReady',
  4 => 'createAndGo',
  5 => 'createAndWait',
  6 => 'destroy',
);

=head1 NAME

Net::SNMP::Mixin::IpCidrRouteTable - mixin class for the mib-II ipCidrRouteTable

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin;

  #...

  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );

  $session->mixer('Net::SNMP::Mixin::IpCidrRouteTable');
  $session->init_mixins;
  snmp_dispatcher();
  $session->init_ok();
  die $session->errors if $session->errors;

  my @routes = $session->get_ip_cidr_route_table();

  foreach my $route (@routes) {
      my $dest     = $route->{ipCidrRouteDest};
      my $mask     = $route->{ipCidrRouteMask};
      my $tos      = $route->{ipCidrRouteTos};
      my $next_hop = $route->{ipCidrRouteNextHop};
      my $if_index = $route->{ipCidrRouteIfIndex};

      print "$dest/$mask/$tos/$next_hop => $if_index/$next_hop\n";
  }

=head1 DESCRIPTION

A Net::SNMP mixin class for mib-II ipCidrRouteTable info.

=head1 MIXIN METHODS

=head2 B<< OBJ->get_ip_cidr_route_table() >>

Returns a sorted list of mib-II ipCidrRouteTable entries. Every list element (route entry) is a hashref with the following fields and values:

    {
        ipCidrRouteDest         => IpAddress,           # tbl index
        ipCidrRouteMask         => IpAddress,           # tbl index
        ipCidrRouteTos          => Integer32,           # tbl index
        ipCidrRouteNextHop      => IpAddress,           # tbl index
        ipCidrRouteIfIndex      => Integer32,
        ipCidrRouteType         => INTEGER,
        ipCidrRouteTypeString   => String,              # resolved enum
        ipCidrRouteProto        => INTEGER,
        ipCidrRouteProtoString  => String,              # resolved enum
        ipCidrRouteAge          => Integer32,
        ipCidrRouteInfo         => OBJECT IDENTIFIER,
        ipCidrRouteNextHopAS    => Integer32,
        ipCidrRouteMetric1      => Integer32,
        ipCidrRouteMetric2      => Integer32,
        ipCidrRouteMetric3      => Integer32,
        ipCidrRouteMetric4      => Integer32,
        ipCidrRouteMetric5      => Integer32,
        ipCidrRouteStatus       => RowStatus,
        ipCidrRouteStatusString => String,              # resolved enum
    }

=cut

sub get_ip_cidr_route_table {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);


  # stash for return values
  my @route_tbl;

  my (
    $ipCidrRouteDest,        $ipCidrRouteMask,
    $ipCidrRouteTos,         $ipCidrRouteNextHop,
    $ipCidrRouteIfIndex,     $ipCidrRouteType,
    $ipCidrRouteTypeString,  $ipCidrRouteProto,
    $ipCidrRouteProtoString, $ipCidrRouteAge,
    $ipCidrRouteInfo,        $ipCidrRouteNextHopAS,
    $ipCidrRouteMetric1,     $ipCidrRouteMetric2,
    $ipCidrRouteMetric3,     $ipCidrRouteMetric4,
    $ipCidrRouteMetric5,     $ipCidrRouteStatus,
    $ipCidrRouteStatusString,
  );

  #
  # index is ipCidrRouteDest,ipCidrRouteMask,ipCidrRouteTos,ipCidrRouteNextHop
  #
  foreach
    my $idx ( oid_lex_sort keys %{ $session->{$prefix}{ipCidrRouteDest} } )
  {
    $ipCidrRouteDest    = $session->{$prefix}{ipCidrRouteDest}{$idx};
    $ipCidrRouteMask    = $session->{$prefix}{ipCidrRouteMask}{$idx};
    $ipCidrRouteTos     = $session->{$prefix}{ipCidrRouteTos}{$idx};
    $ipCidrRouteNextHop = $session->{$prefix}{ipCidrRouteNextHop}{$idx};
    $ipCidrRouteIfIndex = $session->{$prefix}{ipCidrRouteIfIndex}{$idx};

    $ipCidrRouteType = $session->{$prefix}{ipCidrRouteType}{$idx} || -1;
    $ipCidrRouteTypeString = $type_enum{$ipCidrRouteType} || 'unknown';

    $ipCidrRouteProto = $session->{$prefix}{ipCidrRouteProto}{$idx} || -1;
    $ipCidrRouteProtoString = $proto_enum{$ipCidrRouteProto} || 'unknown';

    $ipCidrRouteAge       = $session->{$prefix}{ipCidrRouteAge}{$idx};
    $ipCidrRouteInfo      = $session->{$prefix}{ipCidrRouteInfo}{$idx};
    $ipCidrRouteNextHopAS = $session->{$prefix}{ipCidrRouteNextHopAS}{$idx};
    $ipCidrRouteMetric1   = $session->{$prefix}{ipCidrRouteMetric1}{$idx};
    $ipCidrRouteMetric2   = $session->{$prefix}{ipCidrRouteMetric2}{$idx};
    $ipCidrRouteMetric3   = $session->{$prefix}{ipCidrRouteMetric3}{$idx};
    $ipCidrRouteMetric4   = $session->{$prefix}{ipCidrRouteMetric4}{$idx};
    $ipCidrRouteMetric5   = $session->{$prefix}{ipCidrRouteMetric5}{$idx};

    $ipCidrRouteStatus = $session->{$prefix}{ipCidrRouteStatus}{$idx} || -1;
    $ipCidrRouteStatusString = $status_enum{$ipCidrRouteStatus} || 'unknown';

    push @route_tbl,
      {
      ipCidrRouteDest         => $ipCidrRouteDest,
      ipCidrRouteMask         => $ipCidrRouteMask,
      ipCidrRouteTos          => $ipCidrRouteTos,
      ipCidrRouteNextHop      => $ipCidrRouteNextHop,
      ipCidrRouteIfIndex      => $ipCidrRouteIfIndex,
      ipCidrRouteType         => $ipCidrRouteType,
      ipCidrRouteTypeString   => $ipCidrRouteTypeString,
      ipCidrRouteProto        => $ipCidrRouteProto,
      ipCidrRouteProtoString  => $ipCidrRouteProtoString,
      ipCidrRouteAge          => $ipCidrRouteAge,
      ipCidrRouteInfo         => $ipCidrRouteInfo,
      ipCidrRouteNextHopAS    => $ipCidrRouteNextHopAS,
      ipCidrRouteMetric1      => $ipCidrRouteMetric1,
      ipCidrRouteMetric2      => $ipCidrRouteMetric2,
      ipCidrRouteMetric3      => $ipCidrRouteMetric3,
      ipCidrRouteMetric4      => $ipCidrRouteMetric4,
      ipCidrRouteMetric5      => $ipCidrRouteMetric5,
      ipCidrRouteStatus       => $ipCidrRouteStatus,
      ipCidrRouteStatusString => $ipCidrRouteStatusString,
      };
  }

  return @route_tbl;
}

=head1 INITIALIZATION

=head2 B<< OBJ->_init($reload) >>

Fetch the mib-II ipCidrRouteTable from the host. Don't call this method direct!

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
  # initialize the object for ipCidrRouteTable infos
  _fetch_ip_cidr_route_tbl($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_ip_cidr_route_tbl($session) >>

Fetch the ipCidrRouteTable once during object initialization.

=cut

sub _fetch_ip_cidr_route_tbl {
  my $session = shift;
  my $result;

  # fetch the ipCidrRouteTable
  $result = $session->get_table(
    -baseoid => IP_CIDR_ROUTE_TABLE,

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_ip_cidr_route_tbl_cb ) : (),
  );

  unless ( defined $result ) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  # in nonblocking mode the callback will be called asynchronously
  return 1 if $session->nonblocking;

  # ok we are in synchronous mode, call the result mangling function
  # by hand
  _ip_cidr_route_tbl_cb($session);

}

=head2 B<< _ip_cidr_route_tbl_cb($session) >>

The callback for _fetch_ip_cidr_route_tbl().

=cut

sub _ip_cidr_route_tbl_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  # build parallel hashes, keys are the index:
  #
  # ipCidrRouteDest,ipCidrRouteMask,ipCidrRouteTos,ipCidrRouteNextHop
  #

  $session->{$prefix}{ipCidrRouteDest} =
    idx2val( $vbl, IP_CIDR_ROUTE_DEST, undef, undef, );

  $session->{$prefix}{ipCidrRouteMask} =
    idx2val( $vbl, IP_CIDR_ROUTE_MASK, undef, undef, );

  $session->{$prefix}{ipCidrRouteTos} =
    idx2val( $vbl, IP_CIDR_ROUTE_TOS, undef, undef, );

  $session->{$prefix}{ipCidrRouteNextHop} =
    idx2val( $vbl, IP_CIDR_ROUTE_NEXTHOP, undef, undef, );

  $session->{$prefix}{ipCidrRouteIfIndex} =
    idx2val( $vbl, IP_CIDR_ROUTE_IFINDEX, undef, undef, );

  $session->{$prefix}{ipCidrRouteType} =
    idx2val( $vbl, IP_CIDR_ROUTE_TYPE, undef, undef, );

  $session->{$prefix}{ipCidrRouteProto} =
    idx2val( $vbl, IP_CIDR_ROUTE_PROTO, undef, undef, );

  $session->{$prefix}{ipCidrRouteAge} =
    idx2val( $vbl, IP_CIDR_ROUTE_AGE, undef, undef, );

  $session->{$prefix}{ipCidrRouteInfo} =
    idx2val( $vbl, IP_CIDR_ROUTE_INFO, undef, undef, );

  $session->{$prefix}{ipCidrRouteNextHopAS} =
    idx2val( $vbl, IP_CIDR_ROUTE_NEXTHOPAS, undef, undef, );

  $session->{$prefix}{ipCidrRouteMetric1} =
    idx2val( $vbl, IP_CIDR_ROUTE_METRIC1, undef, undef, );

  $session->{$prefix}{ipCidrRouteMetric2} =
    idx2val( $vbl, IP_CIDR_ROUTE_METRIC2, undef, undef, );

  $session->{$prefix}{ipCidrRouteMetric3} =
    idx2val( $vbl, IP_CIDR_ROUTE_METRIC3, undef, undef, );

  $session->{$prefix}{ipCidrRouteMetric4} =
    idx2val( $vbl, IP_CIDR_ROUTE_METRIC4, undef, undef, );

  $session->{$prefix}{ipCidrRouteMetric5} =
    idx2val( $vbl, IP_CIDR_ROUTE_METRIC5, undef, undef, );

  $session->{$prefix}{ipCidrRouteStatus} =
    idx2val( $vbl, IP_CIDR_ROUTE_STATUS, undef, undef, );

  # this init job is finished
  get_init_slot($session)->{$prefix}--;

  return 1;
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

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin-IpCidrRouteTable


=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2011-2016 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

# vim: sw=2
