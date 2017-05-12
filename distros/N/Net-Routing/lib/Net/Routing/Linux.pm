#
# $Id: Linux.pm,v 717225574cff 2015/11/12 08:46:57 gomor $
#
package Net::Routing::Linux;
use strict;
use warnings;

our $VERSION = '0.44';

use base qw(Net::Routing);

use IPC::Run3;
use Net::IPv4Addr;
use Net::IPv6Addr;
use Net::Routing qw($Error :constants);

sub new {
   my $self = shift->SUPER::new(
      @_,
   ) or return;

   if (! defined($self->path)) {
      $Error = "you must give a `path' attribute";
      return;
   }

   my $family = $self->family;
   if (! defined($family)) {
      $Error = "you must give a `family' attribute";
      return;
   }
   else {
      if ($family ne NR_FAMILY_INET4() && $family ne NR_FAMILY_INET6()) {
         $Error = "family not supported [$family]: use either NR_FAMILY_INET4() or NR_FAMILY_INET6()";
         return;
      }
   }

   return $self;
}

sub get {
   my $self = shift;
   my ($cmd4, $cmd6) = @_;

   my $path = $self->path;
   my $family = $self->family;

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
   };

   $cmd4 ||= [ $bin, '-rnA', 'inet' ];
   $cmd6 ||= [ $bin, '-rnA', 'inet6' ];

   my $cmd = [];
   if ($family eq NR_FAMILY_INET4()) {
     $cmd = $cmd4;
   }
   # If not NR_FAMILY_INET4(), it must be NR_FAMILY_INET6() because we validated family at new()
   else {
     $cmd = $cmd6;
   }

   my $out;
   my $err;
   eval {
      run3($cmd, undef, \$out, \$err);
   };
   # Error in executing run3()
   if ($@) {
      chomp($@);
      $Error = "unable to execute command [".join(' ', @$cmd)."]: $@";
      return;
   }
   # Error in command execution
   elsif ($?) {
      chomp($err);
      $Error = "command execution failed [".join(' ', @$cmd)."]: $err";
      return;
   }

   my $routes = [];

   my @lines = split(/\n/, $out);
   if ($family eq NR_FAMILY_INET4()) {
      $routes = $self->_get_inet4(\@lines);
   }
   # If not NR_FAMILY_INET4(), it must be NR_FAMILY_INET6() because we validated family at new()
   else {
      $routes = $self->_get_inet6(\@lines);
   }

   return $routes;
}

sub _get_inet4 {
   my $self = shift;
   my ($lines) = @_;

   my @routes = ();
   my %cache = ();

   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);
      my $route = $toks[0];
      my $gateway = $toks[1];
      my $netmask = $toks[2];
      my $flags = $toks[3];
      my $mss = $toks[4];
      my $window = $toks[5];
      my $irtt = $toks[6];
      my $interface = $toks[7];

      if (defined($route) && defined($gateway) && defined($interface)
      &&  defined($netmask)) {
         # A first sanity check to help Net::IPv4Addr
         if ($route !~ /^[0-9\.]+$/ || $gateway !~ /^[0-9\.]+$/
         ||  $netmask !~ /^[0-9\.]+$/) {
            next;
         }

         eval {
            my ($ip1, $cidr1) = Net::IPv4Addr::ipv4_parse($route);
            my ($ip2, $cidr2) = Net::IPv4Addr::ipv4_parse($gateway);
            my ($ip3, $cidr3) = Net::IPv4Addr::ipv4_parse($netmask);
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
         if ($route eq '0.0.0.0' && $netmask eq '0.0.0.0') {
            $route{default} = 1;
            $route{route} = NR_DEFAULT_ROUTE4();
         }
         else {
            my ($ip, $cidr) = Net::IPv4Addr::ipv4_parse("$route / $netmask");
            $route{route} = "$ip/$cidr";
         }

         # Local subnet
         if ($gateway eq '0.0.0.0') {
            $route{local} = 1;
            $route{gateway} = NR_LOCAL_ROUTE4();
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

sub _get_inet6 {
   my $self = shift;
   my ($lines) = @_;

   my @routes = ();
   my %cache = ();

   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);
      my $route = $toks[0];
      my $gateway = $toks[1];
      my $flag = $toks[2];
      my $met = $toks[3];
      my $ref = $toks[4];
      my $use = $toks[5];
      my $interface = $toks[6];

      if (defined($route) && defined($gateway) && defined($interface)) {
         # A first sanity check to help Net::IPv6Addr
         if ($route !~ /^[0-9a-f:\/]+$/i || $gateway !~ /^[0-9a-f:\/]+$/i) {
            next;
         }

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
         if ($route eq '::/0' && $interface ne 'lo') {
            $route{default} = 1;
            $route{route} = NR_DEFAULT_ROUTE6();
         }

         # Local subnet
         if ($gateway eq '::') {
            $route{local} = 1;
            $route{gateway} = NR_LOCAL_ROUTE6();
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

Net::Routing::Linux - manage route entries on Linux

=head1 SYNOPSIS

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
