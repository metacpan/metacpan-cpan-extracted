#
# $Id: FreeBSD.pm,v 717225574cff 2015/11/12 08:46:57 gomor $
#
package Net::Routing::FreeBSD;
use strict;
use warnings;

our $VERSION = '0.44';

use base qw(Net::Routing::Linux);

use Net::CIDR;
use Net::IPv4Addr;
use Net::IPv6Addr;
use Net::Routing qw($Error :constants);

sub get {
   my $self = shift;

   my $bin = '';
   {
      local $ENV{LC_ALL} = $self->lc_all;

      for my $path (@{$self->path}) {
         if (-f "$path/netstat") {
            $bin = "$path/netstat";
            last;
         }
      }
      if (! length($bin)) {
         $Error = "unable to find netstat command from current PATH";
         return;
      }
   }

   my $cmd4 = [ $bin, '-rnf', 'inet' ];
   my $cmd6 = [ $bin, '-rnf', 'inet6' ];

   return $self->SUPER::get($cmd4, $cmd6);
}

sub _get_inet4 {
   my $self = shift;
   my ($lines) = @_;

   my @routes = ();
   my %cache = ();

   # FreeBSD 9.x
   # Destination        Gateway            Flags    Refs      Use  Netif Expire
   # default            8.8.210.254        UGS         0 14188719    em0
   #
   # FreeBSD 10.x
   # Destination        Gateway            Flags      Netif Expire
   # default            8.8.25.254         UGS         re0

   my $freebsd_version = '10.x';

   for my $line (@$lines) {
      # FreeBSD 10.1-RELEASE
      if ($line =~ /^\s*destination\s+gateway\s+flags\s+netif\s+expire\s*$/i) {
         #print STDERR "*** DEBUG FreeBSD 10.x\n";
         $freebsd_version = '10.x';
         next;
      }
      # FreeBSD 9.3-RELEASE
      elsif ($line =~ /^\s*destination\s+gateway\s+flags\s+refs\s+use\s+netif\s+expire\s*$/i) {
         #print STDERR "*** DEBUG FreeBSD 9.x\n";
         $freebsd_version = '9.x';
         next;
      }

      my @toks = split(/\s+/, $line);

      my ($route, $gateway, $flags, $refs, $use, $interface, $expire);

      if ($freebsd_version eq '9.x') {
         $route = $toks[0];
         $gateway = $toks[1];
         $flags = $toks[2];
         $refs = $toks[3];
         $use = $toks[4];
         $interface = $toks[5];
         $expire = $toks[6];
      }
      else {  # Default to FreeBSD 10.x
         $route = $toks[0];
         $gateway = $toks[1];
         $flags = $toks[2];
         $interface = $toks[3];
         $expire = $toks[4];
      }

      if (defined($route) && defined($gateway) && defined($interface)) {
         #print STDERR "*** DEBUG $route $gateway $interface\n";

         # Convert FreeBSD strings to universal IP addresses
         if ($route eq 'default') {
            $route = '0.0.0.0/0';
         }
         if ($gateway =~ /^link/) {
            $gateway = '0.0.0.0';
         }

         # Special case: an entry with a MAC address means a direct route
         #if ($gateway =~ /^[a-f0-9]{1,2}:[a-f0-9]{1,2}:[a-f0-9]{1,2}:[a-f0-9]{1,2}:[a-f0-9]{1,2}:[a-f0-9]{1,2}$/i) {
            #my %route = (
               #route => "$route/32",
               #gateway => '0.0.0.0',
               #interface => $interface,
            #);
            #my $id = $self->_to_psv(\%route);
            #if (! exists($cache{$id})) {
               #push @routes, \%route;
               #$cache{$id}++;
            #}
         #}

         # A first sanity check to help Net::IPv4Addr
         if ($gateway !~ m{^[0-9\.]+$} || $route !~ m{^[0-9\.]+(?:/\d+)?$}) {
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

   # FreeBSD 9.3-RELEASE
   # Internet6:
   # Destination                       Gateway                       Flags      Netif Expire
   # ::/96                             ::1                           UGRS        lo0 =>
   # default                           2003:1122:1:ffff:ff:ff:ff:ff  UGS         em0
   # ::1                               link#5                        UH          lo0

   # FreeBSD 10.1-RELEASE
   # Internet6:
   # Destination                       Gateway                       Flags      Netif Expire
   # ::/96                             ::1                           UGRS        lo0
   # ::1                               link#2                        UH          lo0
   # ::ffff:0.0.0.0/96                 ::1                           UGRS        lo0
   # 2003:1122:2:1a00::/56             link#1                        U           re0

   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);

      my $route = $toks[0];
      my $gateway = $toks[1];
      my $flag = $toks[2];
      my $interface = $toks[3];
      my $expire = $toks[4];

      if (defined($route) && defined($gateway) && defined($interface)) {
         # Convert FreeBSD strings to universal IP addresses
         if ($gateway =~ /^link/ || $gateway eq '::1') {
            $gateway = '::';
         }
         if ($route eq 'default') {
            $route = '::/0';
         }
         # Strip interface name from route
         $route =~ s/%[a-z]+\d+//g;

         # Special case: an entry with a MAC address means a default gateway
         if ($gateway =~ /^[a-f0-9]{1,2}:[a-f0-9]{1,2}:[a-f0-9]{1,2}:[a-f0-9]{1,2}:[a-f0-9]{1,2}:[a-f0-9]{1,2}$/i) {
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

Net::Routing::FreeBSD - manage route entries on FreeBSD

=head1 SYNOPSIS

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
