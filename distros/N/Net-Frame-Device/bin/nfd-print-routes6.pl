#!/usr/bin/perl
#
# $Id: nfd-print-routes6.pl 354 2012-11-16 15:28:51Z gomor $
#
use strict;
use warnings;

require Net::IPv6Addr;

sub _getIp6 {
   my ($dev) = @_;
   my $buf = `/sbin/ifconfig $dev 2> /dev/null`;

   my $ip6;
   if ($buf) {
      for (split('\n', $buf)) {
         for (split(/\s+/)) {
            s/(?:%[a-z0-9]+)$//; # This removes %lnc0 on BSD systems
            $ip6 = $_ if Net::IPv6Addr::is_ipv6($_);
            last if $ip6;
         }
         last if $ip6;
      }
   }

   $ip6 =~ s/\/[0-9]+$// if $ip6;

   ($ip6 &&  lc($ip6)) || '::1';
}

sub _getRoutesLinux {
   my %ifRoutes;
   my $buf = `netstat -rnA inet6`;
   my %devIps;
   if ($buf) {
      my @lines = split('\n', $buf);
      for (@lines) {
         my @elts = split(/\s+/);
         if (Net::IPv6Addr::is_ipv6($elts[0])) {
            unless (exists $devIps{interface}) {
               $devIps{$elts[-1]} = _getIp6($elts[-1]);
            }
            my $route = {
               destination => $elts[0],
               nextHop     => $elts[1],
               interface   => $elts[-1],
               ip6         => $devIps{$elts[-1]},
            };
            push @{$ifRoutes{$elts[-1]}}, $route;
         }
      }
   }
   else {
      carp("Unable to get routes\n");
      return undef;
   }
   \%ifRoutes;
}

my $h = _getRoutesLinux();

use Data::Dumper;
print Dumper($h)."\n";
