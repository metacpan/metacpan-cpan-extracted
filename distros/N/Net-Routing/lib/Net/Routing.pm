#
# $Id: Routing.pm,v 717225574cff 2015/11/12 08:46:57 gomor $
#
package Net::Routing;
use strict;
use warnings;

our $VERSION = '0.44';

use base qw(Class::Gomor::Hash);

our @AS = qw(
   path
   lc_all
   target
   family
   _target_type
   _routing_module
   _routes
);
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::CIDR;
use Net::IPv4Addr;
use Net::IPv6Addr;

our $_routing_module;
our $Error;

use constant NR_TARGET_ALL => 'all';
use constant NR_TARGET_DEFAULT => 'default';
use constant NR_FAMILY_INET4 => 'inet4';
use constant NR_FAMILY_INET6 => 'inet6';
use constant NR_DEFAULT_ROUTE4 => '0.0.0.0/0';
use constant NR_DEFAULT_ROUTE6 => '::/0';
use constant NR_LOCAL_ROUTE4 => '0.0.0.0';
use constant NR_LOCAL_ROUTE6 => '::';

use constant _TARGET_TYPE_ALL => 'all';
use constant _TARGET_TYPE_DEFAULT => 'default';
use constant _TARGET_TYPE_IPv4 => 'ipv4';
use constant _TARGET_TYPE_IPv6 => 'ipv6';
use constant _TARGET_TYPE_INTERFACE => 'interface';

our %EXPORT_TAGS = (
   constants => [qw(
      NR_TARGET_ALL
      NR_TARGET_DEFAULT
      NR_FAMILY_INET4
      NR_FAMILY_INET6
      NR_DEFAULT_ROUTE4
      NR_DEFAULT_ROUTE6
      NR_LOCAL_ROUTE4
      NR_LOCAL_ROUTE6
   )],
);

our @EXPORT_OK = (
   '$Error',
   @{$EXPORT_TAGS{constants}},
);

BEGIN {
   if ($^O eq 'linux') {
      return $_routing_module = "Net::Routing::Linux";
   }
   elsif ($^O eq 'freebsd') {
      return $_routing_module = "Net::Routing::FreeBSD";
   }
   elsif ($^O eq 'netbsd') {
      return $_routing_module = "Net::Routing::NetBSD";
   }
   elsif ($^O eq 'darwin') {
      return $_routing_module = "Net::Routing::Darwin";
   }
   #elsif ($^O eq 'MSWin32') {
   #   return $_routing_module = "Net::Routing::MSWin32";
   #}
   #elsif ($^O eq 'openbsd') {
   #   return $_routing_module = "Net::Routing::OpenBSD";
   #}

   die("[-] Net::Routing: Operating System not supported: $^O\n");
}

sub new {
   my $self = shift->SUPER::new(
      path => [ qw(/bin /sbin /usr/bin /usr/sbin /usr/local/bin /usr/local/sbin) ],
      lc_all => 'en_GB.UTF-8',
      target => NR_TARGET_ALL(),
      family => NR_FAMILY_INET4(),
      @_,
   );

   $self->path([ @{$self->path}, split(':', $ENV{PATH}) ]);

   eval("use $_routing_module;");
   if ($@) {
      chomp($@);
      $Error = "unable to load routing module [$_routing_module]: $@";
      return;
   }

   $self->_routing_module($_routing_module);

   my $routes = $self->get or return;

   $self->_routes($routes);

   return $self;
}

sub _get_target_type {
   my $self = shift;
   my ($target) = @_;

   my $target_type = '';

   if ($target eq NR_TARGET_ALL()) {
      $target_type = _TARGET_TYPE_ALL();
   }
   elsif ($target eq NR_TARGET_DEFAULT()) {
      $target_type = _TARGET_TYPE_DEFAULT();
   }
   elsif ($target =~ /^[0-9\.]+$/) {
      eval {
         my ($ip, $cidr) = Net::IPv4Addr::ipv4_parse($target);
      };
      if (! $@) {
         $target_type = _TARGET_TYPE_IPv4();
      }
   }
   elsif ($target =~ /^[0-9a-f:\/]+$/i) {
      eval {
         my $x = Net::IPv6Addr::ipv6_parse($target);
      };
      if (! $@) {
         $target_type = _TARGET_TYPE_IPv6();
      }
   }
   # If it is not an IPv4 nor IPv6 address or default nor all routes,
   # we consider it is an interface.
   else {
      $target_type = _TARGET_TYPE_INTERFACE();
   }

   return $target_type;
}

sub get {
   my $self = shift;

   my $target = $self->target;
   my $family = $self->family;
   my $target_type = $self->_get_target_type($target);

   if ($target_type eq _TARGET_TYPE_IPv4()) {
      $family = NR_FAMILY_INET4();
   }
   elsif ($target_type eq _TARGET_TYPE_IPv6()) {
      $family = NR_FAMILY_INET6();
   }

   my $routes = $self->_routing_module_get or return;
   if ($target_type eq _TARGET_TYPE_ALL()) {
      return $routes;
   }

   # Return only wanted routes
   my @routes = ();
   for my $route (@$routes) {
      # Will return default route only.
      if ($target_type eq _TARGET_TYPE_DEFAULT()) {
         if ($route->{default}) {
            push @routes, $route;
         }
      }
      # Will return routes on interface only.
      elsif ($target_type eq _TARGET_TYPE_INTERFACE()) {
         if ($route->{interface} eq $target) {
            push @routes, $route;
         }
      }
      # Will return local route only.
      elsif ($target_type eq _TARGET_TYPE_IPv4() || $target_type eq _TARGET_TYPE_IPv6()) {
         if ($route->{route}
         &&  $route->{route} ne NR_DEFAULT_ROUTE4()
         &&  $route->{route} ne NR_DEFAULT_ROUTE6()) {
            my $r;
            eval {
               $r = Net::CIDR::cidrlookup($target, $route->{route});
            };
            if (! $@ && $r) {
               push @routes, $route;
            }
         }
      }
   }

   # If no route matches, we will return the default route for types 'ipv4' and 'ipv6'
   if (@routes == 0
   &&  ($target_type eq _TARGET_TYPE_IPv4() || $target_type eq _TARGET_TYPE_IPv6())
   ) {
      for my $route (@$routes) {
         if ($route->{default}) {
            push @routes, $route;
         }
      }
   }

   return \@routes;
}

sub _routing_module_get {
   my $self = shift;

   my $routing_module = $self->_routing_module;

   my $routing;
   eval {
      $routing = $routing_module->new(
         path => $self->path,
         family => $self->family,
      );
   };
   if ($@) {
      chomp($@);
      $Error = "unable to load module [$routing_module]: $@";
      return;
   }
   if (! defined($routing)) {
      return;
   }

   my $routes = $routing->get;
   if (! defined($routes)) {
      return;
   }

   return $routes;
}

sub list {
   my $self = shift;

   printf("%-33s  %-33s  %-10s\n", "Route", "Gateway", "Interface");

   my $routes = $self->_routes;
   for my $route (@$routes) {
      my $route2 = $route->{route};
      my $gateway = $route->{gateway};
      my $interface = $route->{interface};

      printf("%-33s  %-33s  %-10s", $route2, $gateway, $interface);
      if ($route->{local}) {
         print "[local]";
      }
      elsif ($route->{default}) {
         print "[default]";
      }

      print "\n";
   }

   return 1;
}

sub _to_psv {
   my $self = shift;
   my ($route) = @_;

   my $psv = $route->{route}.'|'.$route->{gateway}.'|'.$route->{interface}.'|'.
      (exists($route->{default})?'1':'0').'|'.(exists($route->{local})?'1':'0');

   return $psv;
}

1;

__END__

=head1 NAME

Net::Routing - manage route entries on Operating Systems

=head1 SYNOPSIS

   use Net::Routing qw(:constants);

   my $route = Net::Routing->new(
      target => NR_TARGET_ALL(),
      family => NR_FAMILY_INET4(),
   );

   $route->list;

=head1 DESCRIPTION

This modules is currently just a wrapper around the netstat binary command to query routes on the local machine. Its aim is to normalize the way operating systems display network routes, and makes easy for other Perl modules to query interface routes (L<Net::Frame>, for instance).

=head2 METHODS

=over 4

=item B<new> (ARGS)

Class constructor. Optional target argument can be specified to limit routes to only those matching the target type.

=item B<list>

Will print selected routes in a 'netstat' way.

=item B<get>

=back

=head1 SEE ALSO

L<Net::Frame>, L<Net::Frame::Device>

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
