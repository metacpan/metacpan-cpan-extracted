#
# $Id: Route.pm 57 2012-11-02 16:39:39Z gomor $
#
package Net::Libdnet::Route;
use strict; use warnings;

use base qw(Class::Gomor::Array);

our @AS  = qw(
   _handle
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

use Net::Libdnet qw(:route);

sub new {
   my $self   = shift->SUPER::new(@_);
   my $handle = dnet_route_open() or die("Route::new: unable to open");
   $self->_handle($handle);
   $self;
}

sub add {
   my $self    = shift;
   my ($dst, $gateway) = @_;
   dnet_route_add($self->_handle, {route_dst => $dst, route_gw => $gateway});
}

sub delete {
   my $self    = shift;
   my ($dst, $gateway) = @_;
   dnet_route_delete($self->_handle, {route_dst => $dst, route_gw => $gateway});
}

sub get {
   my $self  = shift,
   my ($dst) = @_;
   my $h = dnet_route_get($self->_handle, {route_dst => $dst});
   return $h->{route_gw} if $h;
   undef;
}

sub loop {
   my $self         = shift;
   my ($sub, $data) = @_;
   dnet_route_loop($self->_handle, $sub, $data || \'');
}

sub DESTROY {
   my $self = shift;
   defined($self->_handle) && dnet_route_close($self->_handle);
}

1;

__END__

=head1 NAME

Net::Libdnet::Route - high level API to access libdnet route_* functions

=head1 SYNOPSIS

XXX

=head1 DESCRIPTION

XXX

=head1 METHODS

=over 4

=item B<new>

=item B<get>

=item B<add>

=item B<delete>

=item B<loop>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=cut
