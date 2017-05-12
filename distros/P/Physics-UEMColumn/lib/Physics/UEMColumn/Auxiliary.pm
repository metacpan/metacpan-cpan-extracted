package Physics::UEMColumn::Auxiliary;

use strict;
use warnings;

=head1 NAME

Physics::UEMColumn::Auxiliary;

=head1 SYNOPSIS

 use Physics::UEMColumn::Auxiliary ':all';

=head1 DESCRIPTION

This module collects all the extra functionality that had no place else to be. In future versions this module may be separated into several modules, though an attempt will be made to preserve backwards compatibility.

=head1 IMPORTING

L<Physics::UEMColumn::Auxiliary> doesn't export anything by default and while any symbol shown below may be requested explicitly, as exporting is its primary purpose, some thought has been put into tagging collections of symbols for importing into scripts. Those tags are:

=cut

use Math::Trig;

use parent 'Exporter';
our %EXPORT_TAGS = ( 
  constants   => [ qw/ pi me qe epsilon_0 vc / ],
  model_funcs => [ qw/ L L_t L_z dLdxi dL_tdxi dL_zdxi / ],
  util_funcs  => [ qw/ join_data / ],
  materials   => [ qw/ Ta / ],
);

our @EXPORT_OK;
push @EXPORT_OK, @$_ for values %EXPORT_TAGS;

$EXPORT_TAGS{'all'} = \@EXPORT_OK;

=head2 :constants

=over

=item pi

The mathematical constant

=item me

The rest mass of an electron (kg)

=item qe

The charge of an electron (C)

=item epsilon_0

The permittivity of free space (electric constant) (F/m)

=item vc

The speed of light in a vacuum (m/s)

=back

=cut

use constant {
  me => 9.1e-31,
  qe => 1.6e-19,
  epsilon_0 => 8.85e-12,
  vc => 2.9979e8,
};

=head2 :materials

Null prototyped functions returning a hash of C<energy_fermi> and C<work_function> suitable for passing to the constructor of a C<Physics::UEMColumn::Photocathode> object.

=over

=item Ta

Tantalum metal

=back

=cut

sub Ta() {
  return (
    energy_fermi => '5.3 eV',
    work_function => '4.25 eV',
  );
}

=head2 :model_funcs

Internal functions related to implementing the AG model (see M&S original paper). These need not be used by the end-user and thus are not described here.

=cut

sub L {
  my ($xi) = @_;

  return 1 if $xi == 1;

  if ($xi > 1) {
    my $sqrt = sqrt(($xi**2) - 1);
    return log($xi + $sqrt) / $sqrt;
  } 

  if ($xi >= 0) {
    my $sqrt = sqrt(1 - ($xi**2));
    return asin($sqrt) / $sqrt;
  } 

  die "xi is out of range";
}

sub L_t {
  my ($xi) = @_;
  my $L = L($xi);

  return 1.5 * ( $L + (($xi**2)*$L - $xi) / (1 - $xi**2) );
}

sub L_z {
  my ($xi) = @_;
  my $L = L($xi);

  return 3 * ($xi**2) * ( $xi * $L - 1) / (($xi**2) - 1)
}

sub dL_tdxi {
  my ($xi) = @_;

  return -3/2 * ((($xi**4)-1)*dLdxi($xi) - 4*$xi*L($xi) + ($xi**2) + 2) / ((($xi**2)-1)**2);
}

sub dL_zdxi {
  my ($xi) = @_;

  return 3*$xi * (($xi**2)*(($xi**2)-1)*dLdxi($xi) + $xi*(($xi**2)+3)*L($xi) + 2) / ((($xi**2)-1)**2);
}

sub dLdxi {
  my ($xi) = @_;

  if ($xi >= 1) {
    return 1/(($xi**2)-1) * (1 - $xi*L($xi));

  } elsif ( $xi >= 0) {
    return $xi/2 * (log(1-($xi**2))-2) / ((1-($xi**2))**(1.5));

  } else {
    die "xi is out of range";
  }
}

=head2 :util_funcs

=over 

=item join_data

Takes two AoA (array of arrayref) references and returns the first, having the second appended to it. Further if the last row of the first and the first row of the second have the same first element (e.g. time) that row is not repeated in the result. This function may be used "in place", as the first array reference is appended to; in other words, one need not use the return value.

=back

=cut

sub join_data {
  my ($container, $new) = @_;

  if ( @$container ) {
    #check for overlap
    if ($container->[-1][0] == $new->[0][0]) {
      pop @$container;
    }
  }

  push @$container, @$new;
  return $container;
}

1;

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Physics-UEMColumn>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
