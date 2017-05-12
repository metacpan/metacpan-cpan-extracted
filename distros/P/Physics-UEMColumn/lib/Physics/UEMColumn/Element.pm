package Physics::UEMColumn::Element;

use Moose;
use namespace::autoclean;

use Method::Signatures;

use MooseX::Types::NumUnit qw/num_of_unit/;
my $meters = num_of_unit('m');

has 'location' => ( isa => $meters, is => 'ro', required => 1);
has 'length'   => ( isa => $meters, is => 'ro', required => 1);

has 'cutoff'   => ( isa => 'Num', is => 'ro', default => 3); # relative distance to ignore effect

method effect () { 
  # return an hashref with code for M_t, M_z and acc_z
  return {};
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Physics::UEMColumn::Element - Base class for "optical" elements in a UEM system

=head1 SYNOPSIS

 package Physics::UEMColumn::MyElement;
 use Moose;
 extends 'Physics::UEMColumn::Element';

=head1 DESCRIPTION

L<Physics::UEMColumn::Element> is a base class for "optical" elements in a UEM system. Mostly it defines the physical bounds of the element. All objects passed to L<Physics::UEMColumn::Column> via C<add_element> must be subclasses of this base.

=head1 ATTRIBUTES

=over

=item C<location>

The position of the center of the element in the column. Unit: m

=item C<length>

The full effective length of the element. "Effective" here means the size that the pulse sees; e.g. the length of the pole piece gap of a magnetic lens. Unit: m

=item C<cutoff>

A number representing the number of C<length>s away from the the center of the element before the element may be safely ignored. The default is C<3>.

=back

=head1 METHODS

=over

=item C<effect>

Returns a hash reference of subroutine references defining the effect that the element has on a pulse's width (C<M_t>), length (C<M_z>) and velocity (C<acc_z>). These subroutine references expect arguments of time, pulse position and pulse velocity (C<t>, C<z>, C<v>), they return a number quantifying this effect. The base class simply returns an empty hash reference. This method is intended to be redefined on subclassing.

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Physics-UEMColumn>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
