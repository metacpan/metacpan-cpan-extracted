package Physics::UEMColumn::MagneticLens;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Physics::UEMColumn::Element'; }

use Method::Signatures;

has 'strength' => ( isa => 'Num', is => 'rw', required => 0);
has 'order' =>    ( isa => 'Int', is => 'ro', default => 1);

method effect () {

  my $lens_z = $self->location;
  my $lens_length = $self->length;
  my $lens_str = $self->strength;
  my $lens_order = $self->order;

  my $cutoff = $self->cutoff;

  my $code = sub {
    my ($t, $pulse_z, $pulse_v) = @_;

    my $prox = ($pulse_z - $lens_z) / ( $lens_length / 2 );
    if (abs($prox) > $cutoff) {
      return 0;
    }

    return $lens_str * exp( - $prox**(2 * $lens_order) );

  };

  return {M_t => $code};

}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Physics::UEMColumn::MagneticLens - A class representing a magnetic lens in a UEM system

=head1 SYNOPSIS

 use Physics::UEMColumn alias => ':standard';
 my $lens = MagneticLens->new(
   location => $position . 'cm',
   length   => $length . 'cm',
   strength => $strength,
 );

=head1 DESCRIPTION

L<Physics::UEMColumn::MagneticLens> is a class representing a magnetic lens in a UEM system. It is a subclass of L<Physics::UEMColumn::Element> and inherits its attributes and methods. Additionally it provides:

=head1 ATTRIBUTES

=over

=item C<stength>

Quantifies the strength of the magnetic lens. While this number is conceptually analytical, in practice this number is very hard to determine other than by comparison to lens in question. With this in mind, no unit is used on this attribute.

=item C<order>

The super-Gaussian order C<exp( - $x ** ( 2 * $order ) )> determining the shape of the lens. Default is C<1> (a Gaussian).

=back

=head1 METHODS

=over

=item C<effect>

Returns a hash reference of effect subroutine references (C<M_t>). See L<Physics::UEMColumn::Element/METHODS> for more.

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Physics-UEMColumn>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

