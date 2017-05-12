#
# $Id: Libdnet6.pm 2005 2015-01-28 18:59:42Z gomor $
#
package Net::Libdnet6;
use strict;
use warnings;

our $VERSION = '0.27';

use base qw(Exporter);

# We also export Net::Libdnet subs (those without 6 at the end)
our @EXPORT = qw(
   addr_cmp6
   addr_bcast6
   addr_net6
   arp_add6
   arp_delete6
   arp_get6
   intf_get6
   intf_get_src6
   intf_get_dst6
   intf_set6
   route_add6
   route_delete6
   route_get6

   addr_cmp
   addr_bcast
   addr_net
   arp_add
   arp_delete
   arp_get
   intf_get
   intf_get_src
   intf_get_dst
   intf_set
   route_add
   route_delete
   route_get
);

use Net::Libdnet;
use Net::IPv6Addr;

my $_pathIfconfig;
my $_pathNetstat;

BEGIN {
   sub _getPathIfconfig {
      my @pathList = qw(
         /sbin/ifconfig /usr/sbin/ifconfig /bin/ifconfig /usr/bin/ifconfig
      );
      for (@pathList) {
         (-f $_) && ($_pathIfconfig = $_) && return 1;
      }
      return;
   }

   sub _getPathNetstat {
      my @pathList = qw(
         /bin/netstat /usr/bin/netstat /sbin/netstat /usr/sbin/netstat
      );
      for (@pathList) {
         (-f $_) && ($_pathNetstat = $_) && return 1;
      }
      return;
   }

   my $osname = {
      linux   => [ \&_get_routes_linux, ],
      freebsd => [ \&_get_routes_bsd,   ],
      openbsd => [ \&_get_routes_bsd,   ],
      netbsd  => [ \&_get_routes_bsd,   ],
      darwin  => [ \&_get_routes_bsd,   ],
   };

   *_get_routes = $osname->{$^O}->[0] || \&_get_routes_other;

   # XXX: No support under Windows for now
   unless ($^O =~ /mswin32|cygwin/i) {
      _getPathIfconfig()
         or die("[-] ".__PACKAGE__.": Unable to find ifconfig command\n");
      _getPathNetstat()
         or die("[-] ".__PACKAGE__.": Unable to find netstat command\n");
   }
}

sub arp_add6    { die("[-] ".__PACKAGE__.": arp_add6: Not supported\n") }
sub arp_delete6 { die("[-] ".__PACKAGE__.": arp_delete6: Not supported\n") }
sub arp_get6    { die("[-] ".__PACKAGE__.": arp_get6: Not supported\n") }

sub intf_set6     { die("[-] ".__PACKAGE__.": intf_set6: Not supported\n") }
sub intf_get_src6 { die("[-] ".__PACKAGE__.": intf_get_src6: Not supported\n") }

sub route_add6    { die("[-] ".__PACKAGE__.": route_add6: Not supported\n") }
sub route_delete6 { die("[-] ".__PACKAGE__.": route_delete6: Not supported\n") }

sub addr_cmp6   { die("[-] ".__PACKAGE__.": addr_cmp6: Not supported\n") }
sub addr_bcast6 { die("[-] ".__PACKAGE__.": addr_bcast6: Not supported\n") }

sub _to_string_preferred  { Net::IPv6Addr->new(shift())->to_string_preferred  }
sub _to_string_compressed { Net::IPv6Addr->new(shift())->to_string_compressed }

sub addr_net6 {
   my $ip6 = shift;

   confess('Usage: addr_net6("$ipv6Address/$prefixlen")'."\n")
      if (! $ip6 || $ip6 !~ /\/\d+/);

   my ($ip, $mask) = split('/', $ip6);
   $ip = _to_string_preferred($ip);
   $mask /= 8; # Convert to number of bytes
   my $subnet;
   my $count = 0;
   for (split(':', $ip)) {
      if ($count < $mask) {
         $subnet .= $_.':';
         $count += 2; # Each element takes two bytes
      }
      else {
         $subnet .= '0:';
      }
   }
   $subnet =~ s/:$//;
   return _to_string_compressed($subnet);
}

sub _get_ip6 {
   my $dev = shift;
   return unless $_pathIfconfig;

   my $buf = `$_pathIfconfig $dev 2> /dev/null`;
   return unless $buf;

   my @ip6 = ();
   for (split('\n', $buf)) {
      my $prefixLenFound;
      my $lastIp6;
      for (split(/\s+/)) {
         s/(?:%[a-z0-9]+)$//; # This removes %lnc0 on BSD systems

         # Some Linux systems do not put the prefix with /number
         if (/^[0-9a-f:]+$/i && Net::IPv6Addr::is_ipv6($_)) {
            $lastIp6 = lc($_);
         }
         # Some newer Linux systems do it
         elsif (/^[0-9a-f:]+\/(\d+)$/i && Net::IPv6Addr::is_ipv6($_)) {
            $lastIp6 = lc($_);
         }

         # Gather prefixlen on *BSD systems
         if (/^\d+$/ && $prefixLenFound) {
            $lastIp6 .= '/'.$_;
            --$prefixLenFound;
         }
         ++$prefixLenFound if /^prefixlen$/i;
      }
      push @ip6, $lastIp6 if $lastIp6;
   }

   # We return the first IP as the main address, others as aliases
   if (@ip6 > 1) {
      return $ip6[0], [ @ip6[1..$#ip6] ];
   }
   elsif (@ip6 == 1) {
      return $ip6[0];
   }
   return;
}

sub intf_get6 {
   my $dev = shift;

   confess('Usage: intf_get6($networkInterface)'."\n")
      unless $dev;

   my $dnet = intf_get($dev) or return;
   my ($ip, $aliases) = _get_ip6($dev);
   $dnet->{addr6}    = $ip      if $ip;
   $dnet->{aliases6} = $aliases if $aliases;

   return $dnet;
}

# XXX: not supported yet
sub _get_routes_other { return; }

sub _get_routes_linux {
   return unless $_pathNetstat;

   my $buf = `$_pathNetstat -rnA inet6 2> /dev/null`;
   return unless $buf;

   my @ifRoutes = ();
   my %devIps;
   for (split('\n', $buf)) {
      my @elts = split(/\s+/);
      if ($elts[0]) {
         if ($elts[0] eq '::/0') { # Default route
            my $route = {
               destination => 'default',
               interface   => $elts[-1],
            };
            if (Net::IPv6Addr::is_ipv6($elts[1])) {
               $route->{nextHop} = $elts[1];
            }
            push @ifRoutes, $route;
         }
         elsif (Net::IPv6Addr::is_ipv6($elts[0])) {
            my $route = {
               destination => $elts[0],
               interface   => $elts[-1],
            };
            if (Net::IPv6Addr::is_ipv6($elts[1])) {
               $route->{nextHop} = $elts[1];
            }
            push @ifRoutes, $route;
         }
      }
   }

   if (@ifRoutes > 1) {
      return \@ifRoutes;
   }

   return;
}

sub _get_routes_bsd {
   return unless $_pathNetstat;

   my $buf = `$_pathNetstat -rnf inet6 2> /dev/null`;
   return unless $buf;

   my @ifRoutes = ();
   my %devIps;
   for (split('\n', $buf)) {
      my @elts = split(/\s+/);

      my $destination = $elts[0] || undef;
      my $gateway = $elts[1] || undef;
      my $flags = $elts[2] || undef;
      my $if = $elts[3] || undef;

      if (defined($destination)) {
         $destination =~ s/%[a-z]+[0-9]+//;
      }
      if (defined($gateway)) {
         $gateway =~ s/%[a-z]+[0-9]+//;
      }

      next if ! defined($destination);

      # FreeBSD > 9.x has a new scheme for default routes:
      # it uses the MAC address of default interface
      if ($gateway
      &&  $gateway =~ /^[a-z0-9]{2}:[a-z0-9]{2}:[a-z0-9]{2}:[a-z0-9]{2}:[a-z0-9]{2}:[a-z0-9]{2}$/i) {
         my $route = {
            destination => 'default',
            interface => $if,
         };
         if (Net::IPv6Addr::is_ipv6($elts[1])) {
            $route->{nextHop} = $destination;
         }
         push @ifRoutes, $route;
      }
      elsif (Net::IPv6Addr::is_ipv6($destination)) {
         my $route = {
            destination => $destination,
            interface   => $if,
         };
         if (Net::IPv6Addr::is_ipv6($gateway)) {
            $route->{nextHop} = $gateway;
         }
         push @ifRoutes, $route;
      }
      elsif ($destination eq 'default') {
         my $route = {
            destination => $destination,
            interface => $if,
         };
         if (Net::IPv6Addr::is_ipv6($gateway)) {
            $route->{nextHop} = $gateway;
         }
         push @ifRoutes, $route;
      }
   }

   if (@ifRoutes > 1) {
      return \@ifRoutes;
   }

   return;
}

sub _is_in_network {
   my ($src, $net, $mask) = @_;
   my $net1 = addr_net6($src.'/'.$mask);
   my $net2 = addr_net6($net.'/'.$mask);
   return $net1 eq $net2;
}

sub intf_get_dst6 {
   my $dst = shift;

   confess('Usage: intf_get_dst6($targetIpv6Address)'."\n")
      unless $dst;

   $dst = _to_string_preferred($dst);

   my $routes = _get_routes() or return;

   # Search network device list for target6
   my @devList = ();
   for my $r (@$routes) {
      my ($net, $mask) = split('/', $r->{destination});

      # If the route is unicast, stop here
      unless ($mask) {
         if ($dst eq $r->{destination}) {
            push @devList, $r->{interface};
            last;
         }
      }
      else {
         $net = _to_string_preferred($net);
         if (_is_in_network($dst, $net, $mask)) {
            push @devList, $r->{interface};
         }
      }
   }

   my @devs;
   if (@devList > 0) {
      @devs = map { intf_get6($_) } @devList;
   }
   else {
      # Not on same network, should use default gw
      for my $r (@$routes) {
         if ($r->{destination} eq 'default') {
            push @devs, intf_get6($r->{interface});
         }
      }
   }

   return unless @devs > 0;

   # Now, search the correct source IP, if multiple found
   my @finalDevs = ();
   for (@devs) {
      # Skip if interface has no IPv6 address
      next unless exists $_->{addr6};

      # If it has multiple IPv6 address, choose the good one
      if (exists $_->{aliases6}) {
         my @ipList = ( $_->{addr6}, @{$_->{aliases6}} );
         for my $i (@ipList) {
            my ($net, $mask) = split('/', $i);

            if (_is_in_network($dst, $net, $mask)) {
               my @ipNotMain = grep {!/^$i$/} @ipList;
               $_->{addr6}    = $i;
               $_->{aliases6} = \@ipNotMain;
            }
         }
      }

      if ($_->{name} =~ /^lo\d*$/ && $dst !~ /^0:0:0:0:0:0:0:1$/) {
         next;
      }

      push @finalDevs, $_;
   }

   wantarray ? @finalDevs : $finalDevs[0];
}

sub _search_next_hop {
   my $dev = shift;
   my ($dst, $hops) = @_;

   return unless exists $dev->{addr6};

   my ($net, $mask) = split('/', $dev->{addr6});
   for my $h (@$hops) {
      if (! _is_in_network($dst, $net, $mask)) {
         for my $i ($dev->{addr6}, @{$dev->{aliases6}}) {
            my ($iNet, $iMask) = split('/', $i);
            if (_is_in_network($h, $iNet, $iMask)) {
               return $h;
            }
         }
      }
   }
   return;
}

sub route_get6 {
   my $dst = shift;

   confess('Usage: route_get6($targetIpv6Address)'."\n")
      unless $dst;

   $dst = _to_string_preferred($dst);

   my @devs = intf_get_dst6($dst) or return;
   return unless @devs > 0;

   my @nextHops = ();
   my $routes = _get_routes() or return;
   for my $r (@$routes) {
      push @nextHops, $r->{nextHop} if $r->{nextHop};
   }

   return unless @nextHops > 0;

   my $nextHop;
   for my $d (@devs) {
      $nextHop = _search_next_hop($d, $dst, \@nextHops);
   }

   return $nextHop;
}

1;

__END__

=head1 NAME

Net::Libdnet6 - adds IPv6 support to Net::Libdnet

=head1 DESCRIPTION

=head1 SUBROUTINES

=over 4

=item B<addr_bcast6>

=item B<addr_cmp6>

=item B<addr_net6>

=item B<arp_add6>

=item B<arp_delete6>

=item B<arp_get6>

=item B<intf_get6>

=item B<intf_get_dst6>

=item B<intf_get_src6>

=item B<intf_set6>

=item B<route_add6>

=item B<route_delete6>

=item B<route_get6>

=back

=head1 SEE ALSO

L<Net::Libdnet>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
