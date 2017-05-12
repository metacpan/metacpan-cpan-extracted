#
# $Id: NetBSD.pm,v 717225574cff 2015/11/12 08:46:57 gomor $
#
package Net::Routing::NetBSD;
use strict;
use warnings;

our $VERSION = '0.44';

use base qw(Net::Routing::FreeBSD);

use Net::IPv4Addr;
use Net::IPv6Addr;
use Net::CIDR;
use Net::Routing qw($Error :constants);

sub _get_inet4 {
   my $self = shift;
   my ($lines) = @_;

   my @routes = ();
   my %cache = ();

   # NetBSD
   # Destination        Gateway            Flags     Refs     Use    Mtu  Interface
   # default            208.44.95.1        UGS         0   330309   1500  ex0

   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);

      my ($route, $gateway, $flags, $refs, $use, $mtu, $interface);

      $route = $toks[0];
      $gateway = $toks[1];
      $flags = $toks[2];
      $refs = $toks[3];
      $use = $toks[4];
      $mtu = $toks[5];
      $interface = $toks[6];

      if (defined($route) && defined($gateway) && defined($interface)) {
         #print STDERR "*** DEBUG $route $gateway $interface\n";

         # Convert NetBSD strings to "universal" IP addresses
         if ($route eq 'default') {
            $route = '0.0.0.0/0';
         }
         if ($gateway =~ /^link/) {
            $gateway = '0.0.0.0';
         }

         # A first sanity check to help Net::IPv4Addr
         if ($gateway !~ m{^[0-9\.]+$} || $route !~ m{^[0-9\.]+(?:/\d+)?$}) {
            #print STDERR "*** SKIP [$gateway] [$route]\n";
            next;
         }

         # Normalize IP addresses
         $route = Net::CIDR::range2cidr($route);    # 127.16 => 172.16/16
         $route = Net::CIDR::cidrvalidate($route);  # 172.16/16 => 172.16.0.0/16

         eval {
            my ($ip1, $cidr1) = Net::IPv4Addr::ipv4_parse($route);
            my ($ip2, $cidr2) = Net::IPv4Addr::ipv4_parse($gateway);
         };
         if ($@) {
            #chomp($@);
            #print "*** DEBUG[$@]\n";
            next; # Not a valid line for us.
         }

         # Ok, proceed.
         my %route = (
            route => $route,
            gateway => $gateway,
            interface => $interface,
         );

         # Default route
         if ($route eq '0.0.0.0/0') {
            $route{default} = 1;
            $route{route} = NR_DEFAULT_ROUTE4();
         }

         # Local subnet
         if ($gateway eq '0.0.0.0') {
            $route{local} = 1;
            $route{gateway} = NR_LOCAL_ROUTE4();
         }

         if ($route{route} !~ /\/\d+$/) {
            $route{route} .= '/32';
         }

         my $id = $self->_to_psv(\%route);
         if (! exists($cache{$id})) {
            #print STDERR "*** DEBUG new $id\n";
            push @routes, \%route;
            $cache{$id}++;
         }
      }
   }

   return \@routes;
}

sub _get_inet6 {
   my $self = shift;
   my ($lines) = @_;

   my @routes = ();
   my %cache = ();

   # NetBSD
   # Internet6:
   # Destination                   Gateway                   Flags     Refs     Use Mtu  Interface
   # ::/104                        ::1                       UGRS        0        0 33228  lo0 =>
   # ::/96                         ::1                       UGRS        0        0

   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);

      my $route = $toks[0];
      my $gateway = $toks[1];
      my $flags = $toks[2];
      my $refs = $toks[3];
      my $use = $toks[4];
      my $mtu = $toks[5];
      my $interface = $toks[6];

      if (defined($route) && defined($gateway) && defined($interface)) {
         # Convert NetBSD strings to "universal" IP addresses
         if ($gateway =~ /^link/ || $gateway eq '::1') {
            $gateway = '::';
         }
         if ($route eq 'default') {
            $route = '::/0';
         }

         # Special case: an entry with a MAC address means a default gateway
         if ($gateway =~ /^[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}:[a-f0-9]{2}$/) {
            my %route = (
               route => NR_DEFAULT_ROUTE6(),
               gateway => $route,
               interface => $interface,
            );
            my $id = $self->_to_psv(\%route);
            if (! exists($cache{$id})) {
               push @routes, \%route;
               $cache{$id}++;
            }
         }

         # A first sanity check to help Net::IPv6Addr
         if ($route !~ m{^[0-9a-f:/]+$}i || $gateway !~ m{^[0-9a-f:/]+$}i) {
            next;
         }

         #print STDERR "*** DEBUG $route $gateway $interface\n";

         eval {
            #print "*** DEBUG $route $gateway\n";
            my $ip1 = Net::IPv6Addr::ipv6_parse($route);
            my $ip2 = Net::IPv6Addr::ipv6_parse($gateway);
         };
         if ($@) {
            #chomp($@);
            #print "*** DEBUG[$@]\n";
            next; # Not a valid line for us.
         }

         # Ok, proceed.
         my %route = (
            route => $route,
            gateway => $gateway,
            interface => $interface,
         );

         # Default route
         if ($route eq '::/0') {
            $route{default} = 1;
            $route{route} = NR_DEFAULT_ROUTE6();
         }

         # Local subnet
         if ($gateway eq '::') {
            $route{local} = 1;
            $route{gateway} = NR_LOCAL_ROUTE6();
         }

         if ($route{route} !~ /\/\d+$/) {
            $route{route} .= '/128';
         }

         my $id = $self->_to_psv(\%route);
         if (! exists($cache{$id})) {
            push @routes, \%route;
            $cache{$id}++;
         }
      }
   }

   return \@routes;
}

1;

__END__

=head1 NAME

Net::Routing::NetBSD - manage route entries on NetBSD

=head1 SYNOPSIS

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
