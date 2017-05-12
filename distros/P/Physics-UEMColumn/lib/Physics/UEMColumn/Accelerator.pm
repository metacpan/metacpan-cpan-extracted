package Physics::UEMColumn::Accelerator;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Physics::UEMColumn::Element'; }

use Method::Signatures;

has '+location' => ( required => 0, default => 0 );

method field () {
  return 0;
}

method est_exit_vel () {
  return 0;
}

method est_exit_time () {
  return 0;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Physics::UEMColumn::Accelerator - Base class for acceleration regions in a UEM system

=head1 SYNOPSIS

 package Physics::UEMColumn::MyAccelerator;
 use Moose;
 extends 'Physics::UEMColumn::Accelerator';

=head1 DESCRIPTION

L<Physics::UEMColumn::Accelerator> is a base class for acceleration regions in a UEM system. It is itself a subclass of L<Physics::UEMColumn::Element> and inherits its attributes and methods. Additionally it provides:

=head1 ATTRIBUTES

=over

=item C<location>

Unlike L<Physics::UEMColumn::Element>, accelerators' location defines the start of the region and defaults to a C<0>.

=back

=head1 METHODS

=over

=item C<field>

Returns a field strength possibly derived from other attributes. In this base class it simply returns zero. This method is intended to be redefined on subclassing.

=item C<est_exit_vel>

Returns an estimate of the velocity of the pulse on exiting the region. This in not likely to be exact. It is used in estimating the end time of the simulation. The base class' implementation returns zero and is intended to be subclassed.

=item C<est_exit_time>

Returns an estimate of the time that the pulse on exits the region. This in not likely to be exact. It is used in estimating the end time of the simulation. The base class' implementation returns zero and is intended to be subclassed.

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Physics-UEMColumn>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

