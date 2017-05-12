# POE::Component::IRC::Service
# By Chris Williams <chris@bingosnet.co.uk>
# 
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::IRC::Service;

# This is just a wrapper for the following modules

use strict;
use POE::Component::IRC::Service::P10;
use POE::Component::IRC::Service::Hybrid;
use Carp;
use vars qw($VERSION);

$VERSION = '0.998';

sub new {
  my ($package,$alias,$ircdtype) = splice @_, 0, 3;
  my $object;

  unless ($alias and $ircdtype) {
    croak "Not enough arguments to POE::Component::IRC::Service::new()";
  }

  SWITCH: {
    if ($ircdtype =~ /^p10$/i) {
	$object = POE::Component::IRC::Service::P10->new($alias,@_);
    	last SWITCH;
    }
    if ($ircdtype =~ /^Hybrid$/i) {
        croak "Not implemented yet";
	$object = POE::Component::IRC::Service::Hybrid->new($alias,@_);
	last SWITCH;
    }
    croak "Don't know that IRCD type sorry";
  }
  return $object;
}

1;
__END__

=head1 NAME

POE::Component::IRC::Service - a fully event driven IRC Services module

=head1 SYNOPSIS

  use POE::Component::IRC::Service;

  # Do this when you create your sessions. 'IRC-Service' is just a
  # kernel alias to christen the new IRC connection with. Returns an
  # object to access the IRC network state.

  my ($ircservice) = POE::Component::IRC::Service->new('IRC-Service','P10') or die "Oh noooo! $!";

=head1 DESCRIPTION

POE::Component::IRC::Service is a POE component borrowed heavily from POE::Component::IRC 
which acts as an easily controllable IRC Services client for your other POE components and
sessions.

The module is a wrapper for various sub components which actually deal with the messy business
of connecting to and returning events from the IRC network, and recording the IRC network state.

=head1 METHODS

=over

=item new

Takes three arguments: a name (kernel alias) which this new connection
will be known by; the name of the sub-component to invoke; a hashref containing configuration information. Currently
implemented is P10. Hybrid support will be coming soon.

Returns a brand new shiny IRC Service object.

=back

=head1 AUTHOR

Chris Williams, E<lt>chris@bingosnet.co.ukE<gt>

=head1 LICENSE

Copyright (c) Dennis Taylor and Chris Williams.

This module may be used, modified, and distributed under the same
terms as Perl itself. Please see the license that came with your Perl
distribution for details.

=head1 MAD PROPS

The biggest debt is to Dennis Taylor, E<lt>dennis@funkplanet.comE<gt> for 
creating POE::Component::IRC and letting me "salvage" his code for this module.

=head1 SEE ALSO

RFC 1459, http://www.irchelp.org/, http://poe.perl.org/,
POE::Component::IRC
POE::Component::IRC::Service::P10
POE::Component::IRC::Service::Hybrid
