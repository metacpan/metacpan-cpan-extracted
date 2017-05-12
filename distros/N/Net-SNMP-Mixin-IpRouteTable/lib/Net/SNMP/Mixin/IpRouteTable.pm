package Net::SNMP::Mixin::IpRouteTable;

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
use Net::SNMP qw/oid_lex_sort/;
use Net::SNMP::Mixin::Util qw/idx2val push_error get_init_slot/;

#
# this module export config
#
my @mixin_methods;

BEGIN {
  @mixin_methods = (qw/ get_ip_route_table /);
}

use Sub::Exporter -setup => {
  exports => [@mixin_methods],
  groups  => { default => [@mixin_methods], },
};

#
# SNMP oid constants used in this module
#
# from mib-II
use constant {
  IP_ROUTE_TABLE => '1.3.6.1.2.1.4.21',

  IP_ROUTE_DEST    => '1.3.6.1.2.1.4.21.1.1',
  IP_ROUTE_IFINDEX => '1.3.6.1.2.1.4.21.1.2',
  IP_ROUTE_METRIC1 => '1.3.6.1.2.1.4.21.1.3',
  IP_ROUTE_METRIC2 => '1.3.6.1.2.1.4.21.1.4',
  IP_ROUTE_METRIC3 => '1.3.6.1.2.1.4.21.1.5',
  IP_ROUTE_METRIC4 => '1.3.6.1.2.1.4.21.1.6',
  IP_ROUTE_NEXTHOP => '1.3.6.1.2.1.4.21.1.7',
  IP_ROUTE_TYPE    => '1.3.6.1.2.1.4.21.1.8',
  IP_ROUTE_PROTO   => '1.3.6.1.2.1.4.21.1.9',
  IP_ROUTE_AGE     => '1.3.6.1.2.1.4.21.1.10',
  IP_ROUTE_MASK    => '1.3.6.1.2.1.4.21.1.11',
  IP_ROUTE_METRIC5 => '1.3.6.1.2.1.4.21.1.12',
  IP_ROUTE_INFO    => '1.3.6.1.2.1.4.21.1.13',
};

#
# the ipRouteType enum
#
my %ip_route_type_enum = (
  1 => 'other',
  2 => 'invalid',
  3 => 'direct',
  4 => 'indirect',
);

#
# the ipRouteProto enum
#
my %ip_route_proto_enum = (
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
);

=head1 NAME

Net::SNMP::Mixin::IpRouteTable - mixin class for the mib-II ipRouteTable

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use Net::SNMP;
  use Net::SNMP::Mixin;

  #...

  my $session = Net::SNMP->session( -hostname => 'foo.bar.com' );

  $session->mixer('Net::SNMP::Mixin::IpRouteTable');
  $session->init_mixins;
  snmp_dispatcher();
  $session->init_ok();
  die $session->errors if $session->errors;

  my @routes = get_ip_route_table();

  foreach my $route ( @routes ) {

    my $dest      = $route->{ipRouteDest};
    my $mask      = $route->{ipRouteMask};
    my $nhop      = $route->{ipRouteNextHop};
    my $proto_str = $route->{ipRouteProtoString};
    my $type_str  = $route->{ipRouteTypeString};

    print "$dest/$mask => $nhop $proto_str $type_str\n";
  }

=head1 DESCRIPTION

A Net::SNMP mixin class for mib-II ipRouteTable info.

=head1 MIXIN METHODS

=head2 B<< OBJ->get_ip_route_table() >>

Returns the mib-II ipRouteTable as a list. Every route entry is a reference to a hash with the following fields and values:

  {
    ipRouteDest       => IpAddress,
    ipRouteMask       => IpAddress,
    ipRouteNextHop    => IpAddress,
    ipRouteIfIndex    => INTEGER,
    ipRouteMetric1    => INTEGER,
    ipRouteMetric2    => INTEGER,
    ipRouteMetric3    => INTEGER,
    ipRouteMetric4    => INTEGER,
    ipRouteMetric5    => INTEGER,
    ipRouteType       => INTEGER,
    ipRouteTypeString => String,   # resolved enum
    ipRouteProto      => INTEGER,
    ipRouteTypeProto  => String,   # resolved enum
    ipRouteAge        => INTEGER,
    ipRouteInfo       => OBJECT IDENTIFIER
  }

=cut

sub get_ip_route_table {
  my $session = shift;
  my $agent   = $session->hostname;

  Carp::croak "$agent: '$prefix' not initialized,"
    unless $session->init_ok($prefix);

  # stash for return values
  my @route_tbl;

  my (
    $ipRouteDest,       $ipRouteMask,    $ipRouteNextHop,     $ipRouteIfIndex, $ipRouteMetric1,
    $ipRouteMetric2,    $ipRouteMetric3, $ipRouteMetric4,     $ipRouteMetric5, $ipRouteType,
    $ipRouteTypeString, $ipRouteProto,   $ipRouteProtoString, $ipRouteAge,     $ipRouteInfo,
  );

  # index is ipRouteDest
  foreach my $idx ( oid_lex_sort keys %{ $session->{$prefix}{ipRouteDest} } ) {

    $ipRouteDest        = $session->{$prefix}{ipRouteDest}{$idx};
    $ipRouteMask        = $session->{$prefix}{ipRouteMask}{$idx};
    $ipRouteNextHop     = $session->{$prefix}{ipRouteNextHop}{$idx};
    $ipRouteIfIndex     = $session->{$prefix}{ipRouteIfIndex}{$idx};
    $ipRouteMetric1     = $session->{$prefix}{ipRouteMetric1}{$idx};
    $ipRouteMetric2     = $session->{$prefix}{ipRouteMetric2}{$idx};
    $ipRouteMetric3     = $session->{$prefix}{ipRouteMetric3}{$idx};
    $ipRouteMetric4     = $session->{$prefix}{ipRouteMetric4}{$idx};
    $ipRouteMetric5     = $session->{$prefix}{ipRouteMetric5}{$idx};
    $ipRouteType        = $session->{$prefix}{ipRouteType}{$idx} || -1;
    $ipRouteTypeString  = $ip_route_type_enum{$ipRouteType} || 'unknown';
    $ipRouteProto       = $session->{$prefix}{ipRouteProto}{$idx} || -1;
    $ipRouteProtoString = $ip_route_proto_enum{$ipRouteProto}
      || 'unknown';
    $ipRouteAge  = $session->{$prefix}{ipRouteAge}{$idx};
    $ipRouteInfo = $session->{$prefix}{ipRouteInfo}{$idx};

    push @route_tbl,
      {
      ipRouteDest        => $ipRouteDest,
      ipRouteMask        => $ipRouteMask,
      ipRouteNextHop     => $ipRouteNextHop,
      ipRouteIfIndex     => $ipRouteIfIndex,
      ipRouteMetric1     => $ipRouteMetric1,
      ipRouteMetric2     => $ipRouteMetric2,
      ipRouteMetric3     => $ipRouteMetric3,
      ipRouteMetric4     => $ipRouteMetric4,
      ipRouteMetric5     => $ipRouteMetric5,
      ipRouteType        => $ipRouteType,
      ipRouteTypeString  => $ipRouteTypeString,
      ipRouteProto       => $ipRouteProto,
      ipRouteProtoString => $ipRouteProtoString,
      ipRouteAge         => $ipRouteAge,
      ipRouteInfo        => $ipRouteInfo,
      };
  }

  return @route_tbl;
}

=head1 INITIALIZATION

=head2 B<< OBJ->_init($reload) >>

Fetch the mib-II ipRouteTable from the host. Don't call this method direct!

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
  # initialize the object for ipRouteTable infos
  _fetch_ip_route_tbl($session);
  return if $session->error;

  return 1;
}

=head1 PRIVATE METHODS

Only for developers or maintainers.

=head2 B<< _fetch_ip_route_tbl($session) >>

Fetch the ipRouteTable once during object initialization.

=cut

sub _fetch_ip_route_tbl {
  my $session = shift;
  my $result;

  # fetch the ipRouteTable
  $result = $session->get_table(
    -baseoid => IP_ROUTE_TABLE,

    # define callback if in nonblocking mode
    $session->nonblocking ? ( -callback => \&_ip_route_tbl_cb ) : (),
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
  _ip_route_tbl_cb($session);

}

=head2 B<< _ip_route_tbl_cb($session) >>

The callback for _fetch_ip_route_tbl().

=cut

sub _ip_route_tbl_cb {
  my $session = shift;
  my $vbl     = $session->var_bind_list;

  unless ( defined $vbl ) {
    if (my $err_msg = $session->error) {
      push_error($session, "$prefix: $err_msg");
    };
    return;
  }

  # mangle result table to get plain idx->value
  #
  # result hashes: ipRouteDest => values
  #

  $session->{$prefix}{ipRouteDest} =
    idx2val( $vbl, IP_ROUTE_DEST, undef, undef, );

  $session->{$prefix}{ipRouteIfIndex} =
    idx2val( $vbl, IP_ROUTE_IFINDEX, undef, undef, );

  $session->{$prefix}{ipRouteMetric1} =
    idx2val( $vbl, IP_ROUTE_METRIC1, undef, undef, );

  $session->{$prefix}{ipRouteMetric2} =
    idx2val( $vbl, IP_ROUTE_METRIC2, undef, undef, );

  $session->{$prefix}{ipRouteMetric3} =
    idx2val( $vbl, IP_ROUTE_METRIC3, undef, undef, );

  $session->{$prefix}{ipRouteMetric4} =
    idx2val( $vbl, IP_ROUTE_METRIC4, undef, undef, );

  $session->{$prefix}{ipRouteMetric5} =
    idx2val( $vbl, IP_ROUTE_METRIC5, undef, undef, );

  $session->{$prefix}{ipRouteNextHop} =
    idx2val( $vbl, IP_ROUTE_NEXTHOP, undef, undef, );

  $session->{$prefix}{ipRouteType} =
    idx2val( $vbl, IP_ROUTE_TYPE, undef, undef, );

  $session->{$prefix}{ipRouteProto} =
    idx2val( $vbl, IP_ROUTE_PROTO, undef, undef, );

  $session->{$prefix}{ipRouteAge} =
    idx2val( $vbl, IP_ROUTE_AGE, undef, undef, );

  $session->{$prefix}{ipRouteMask} =
    idx2val( $vbl, IP_ROUTE_MASK, undef, undef, );

  $session->{$prefix}{ipRouteInfo} =
    idx2val( $vbl, IP_ROUTE_INFO, undef, undef, );

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

  RT: http://rt.cpan.org/Public/Dist/Display.html?Name=Net-SNMP-Mixin-IpRouteTable


=head1 AUTHOR

Karl Gaissmaier <karl.gaissmaier at uni-ulm.de>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2016 Karl Gaissmaier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

# vim: sw=2
