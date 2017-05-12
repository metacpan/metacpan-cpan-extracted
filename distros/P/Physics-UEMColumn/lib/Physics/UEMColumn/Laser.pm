package Physics::UEMColumn::Laser;

use Moose;
use namespace::autoclean;

use MooseX::Types::NumUnit qw/num_of_unit/;

has 'energy'   => ( isa => num_of_unit('J'), is => 'ro', required => 1 );
has 'width'    => ( isa => num_of_unit('m'), is => 'rw', required => 1 );
has 'duration' => ( isa => num_of_unit('s'), is => 'rw', required => 1 );

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Physics::UEMColumn::Laser

=head1 SYNOPSIS

 use strict;
 use warnings;

 use Physics::UEMColumn alias => ':standard';

 my $laser = Laser->new(
   energy   => '4.75 eV',
   width    => '500 um',
   duration => '4 ps',
 );

=head1 DESCRIPTION

L<Physics::UEMColumn::Laser> is a class representing a laser object for L<Physics::UEMColumn>. L<Physics::UEMColumn::Column> objects need a laser object in order to be able create a L<Physics::UEMColumn::Pulse> object.

=head1 ATTRIBUTES

=over

=item C<energy>

A number representing the photon energy of the laser. Unit: J

=item C<width>

A number representing the HW1/eM Gaussian beam width of the laser (at the photocathode). Unit: m

=item C<duration>

A number representing the pulse duration of the laser (at the photocathode). Unit: s

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Physics-UEMColumn>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



