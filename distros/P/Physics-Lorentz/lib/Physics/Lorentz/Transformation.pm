package Physics::Lorentz::Transformation;

use 5.006;
use strict;
use warnings;
use PDL;
use Params::Util qw/_INSTANCE _ARRAY/;
use Carp qw/croak/;

our $VERSION = '0.01';

use constant EPS => 1e-12;

use overload
    '""' => \&stringify,
    '*' => \&_overload_multiply,
    ;

=head1 NAME

Physics::Lorentz::Transformation - Representation of Poincare Transformations

=head1 SYNOPSIS

  use Physics::Lorentz;
  my $rotation = Physics::Lorentz::Transformation->rotation_euler(
    $alpha, $beta, $gamma
  );
  my $vector = Physics::Lorentz::Vector->new([$t, $x, $y, $z]);
  my $rotated = $rotation->apply($vector);
  # or: $rotated = $rotation * $vector;
  
  ...

=head1 DESCRIPTION

This class represents a Poincare transformation. That is a proper or
improper Lorentz transformation plus a shift by some 4-vector.
(C<x' = lamda*x + a>)

Yes, the class name might be misleading, but honestly, when most non-physicists
talk about Lorentz transformations, they mean Poincare transformations anyway.
(Pun intended.)

To sum this up, the set of Poincare transformations contains, among others

=over 2

=item * Boosts

=item * Rotations

=item * Space Inversions / Parity

=item * Time Inversion

=item * Shifts by a constant vector

=item * Combinations thereof

=back

=head2 EXPORT

None.

=head2 OVERLOADED INTERFACE

Stringification is overloaded with the C<stringify> method.

Multiplication (*) is overloaded with the C<merge> method for other
transformations:
C<$t3 = $t1 * $t2> corresponds to the following application on a vector:
C<t1 * ( t2 * vec )>. (I.e. t2 first, then t1)
Of course, B<Poincare transformations do not commute>!

The assignment form of multiplication is supported for merging transformations
but its use is discouraged unless you're into obfuscation.

Multiplication is also overloaded for application to vectors, but only if the
vector is on the right of the transformation: C<$t * $v> is okay, but C<$v * $t>
is not.

=head1 CONSTRUCTORS

=cut

=head2 new

Creates a new C<Physics::Lorentz::Transformation> object.
Defaults to the unity transformation.

If one argument is present, this argument may either be a 4x4 PDL which will
be used internally as the PDL representation of the or an equivalent Perl
datastructure (4x4 matrix).

If two arguments are present, the second argument will be used as or
converted to a L<Physics::Lorentz::Vector>. It defaults to C<[0, 0, 0, 0]>

This result will be of the form C<x' = lamda * x + a> where C<lamda> is the
matrix and C<a> is the vector. (And C<x> is the 4-vector that's acted upon.)

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    if (_INSTANCE($proto, 'Physics::Lorentz::Transformation')) {
        $self = $proto->clone();
    }

    my $matrix = shift;
    my $vector = shift;

    if (ref(_INSTANCE($matrix, 'PDL'))) {
        my ($x, $y) = $matrix->dims;
        if ($x == 4 and $y == 4) {
            $matrix = $matrix->new();
        }
        else {
            croak("${class}->new() needs a 4x4 matrix as PDL or Perl data structure");
        }
        $self->{matrix} = $matrix;
    }
    elsif (_ARRAY($matrix) and @$matrix == 4) {
        my $pdl = pdl $matrix;
        my ($x, $y) = $pdl->dims;
        unless ($x == 4 and $y == 4) {
            croak("${class}->new() needs a 4x4 matrix as PDL or Perl data structure");
        }
        $self->{matrix} = $pdl;
    }
    elsif (not defined $matrix) {
        $self->{matrix} = identity(4) if not defined $self->{matrix};
    }
    else {
        croak("${class}->new() needs a 4x4 matrix as PDL or Perl data structure");
    }
   
    if (_INSTANCE($vector, 'Physics::Lorentz::Vector')) {
        $self->{vector} = $vector;
    }
    elsif (not defined $vector) {
        $self->{vector} = Physics::Lorentz::Vector->new()
          if not defined $self->{vector};
    }
    else {
        my $vec;
        eval { $vec = Physics::Lorentz::Vector->new($vector); };
        if ($@ or not _INSTANCE($vec, 'Physics::Lorentz::Vector')) {
            croak("${class}->new() needs a 4x4 matrix as PDL or Perl data structure");
        }

        $self->{vector} = $vec;
    }

    return bless($self => $class);
}

=head2 rotation_euler

Alternative constructor to construct a specific type of Lorentz transformation:
A 3D rotation with the Euler angles alpha, beta, gamma.

Three arguments: alpha, beta, gamma.

(First rotate about fixed z-axis by alpha, the about fixed y-axis about
beta, then about fixed z-axis by gamma.)

=cut

sub rotation_euler {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my ($gamma, $beta, $alpha) = @_;

    my $ca = cos $alpha;
    my $cb = cos $beta;
    my $cg = cos $gamma;
    my $sa = sin $alpha;
    my $sb = sin $beta;
    my $sg = sin $gamma;

    my $m = pdl([
        [ 1, 0,                    0,        0                    ],
        [ 0, $cg*$cb*$ca-$sa*$sg, $cg*$cb*$sa+$sg*$ca, -$cg*$sb ],
        [ 0, -$sg*$cb*$ca-$cg*$sa, -$sg*$cb*$sa+$cg*$ca, $sg*$sb ],
        [ 0, $sb*$ca, $sb*$sa, $cb ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}

=head2 rotation_x

Alternative constructor to construct a specific type of Lorentz transformation:
A 3D rotation about the x or 1-axis. First argument is the rotation angle.

=cut

sub rotation_x {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my ($phi) = @_;

    my $cp = cos $phi;
    my $sp = sin $phi;

    my $m = pdl([
        [ 1, 0, 0,    0   ],
        [ 0, 1, 0,    0   ],
        [ 0, 0, $cp,  $sp ],
        [ 0, 0, -$sp, $cp ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}

=head2 rotation_y

Alternative constructor to construct a specific type of Lorentz transformation:
A 3D rotation about the y or 2-axis. First argument is the rotation angle.

=cut

sub rotation_y {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my ($phi) = @_;

    my $cp = cos $phi;
    my $sp = sin $phi;

    my $m = pdl([
        [ 1, 0, 0,    0   ],
        [ 0, $cp, 0, -$sp ],
        [ 0, 0,   1, 0    ],
        [ 0, $sp, 0, $cp  ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}

=head2 rotation_z

Alternative constructor to construct a specific type of Lorentz transformation:
A 3D rotation about the z or 3-axis. First argument is the rotation angle.

=cut

sub rotation_z {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my ($phi) = @_;

    my $cp = cos $phi;
    my $sp = sin $phi;

    my $m = pdl([
        [ 1, 0,    0,   0 ],
        [ 0, $cp,  $sp, 0 ],
        [ 0, -$sp, $cp, 0 ],
        [ 0, 0,    0,   1 ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}

=head2 boost

Alternative constructor to construct a specific type of Lorentz transformation:
A boost of rapidity C<eta> (C<eta = atanh(v/c)>) and direction C<x>.

Accepts three arguments: The components of the boost's velocity vector
divided by the speed of light: C<(v1/c, v2/c, v3/c)>.

=cut

sub boost {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my ($v1, $v2, $v3) = @_;

    if (not grep { abs($_) > EPS } ($v1, $v2, $v3)) {
        return $class->new(); # identity
    }

    my ($to_z, $inv_to_z) = _rotate_to_z($v1, $v2, $v3);
    my $boost_z = $class->boost_z(
        sqrt($v1**2 + $v2**2 + $v3**2)
    );
#    my $inv_to_z = $to_z->inv;
    $boost_z->{matrix} = $inv_to_z x $boost_z->{matrix};
    $boost_z->{matrix} = $boost_z->{matrix} x $to_z;
    
    return $boost_z;
}

sub _rotate_to_z {
    my ($x, $y, $z) = @_;
    my $v = pdl([[1],[$x],[$y],[$z]]);

    # done if already on z
    if (abs($x) < EPS and abs($y) < EPS) {
        my $identity = identity(4,4);
        my $sgn = ( ($z < 0) ? -1 : 1 );
        $identity->slice('1:3,1:3') *= $sgn;;
        return( $identity, $identity->copy );
    }

    my $xy        = $x**2 + $y**2;
    my $zsq       = $z**2;
    my $sqrtxy    = sqrt($xy);
    my $i_sqrtxy  = 1 / $sqrtxy;
    my $i_sqrtxyz = 1 / sqrt($xy + $zsq);
    

    my $to_xz_plane = pdl( [
        [ 1, 0,               0,              0 ],
        [ 0, $x * $i_sqrtxy,  $y * $i_sqrtxy, 0 ],
        [ 0, -$y * $i_sqrtxy, $x * $i_sqrtxy, 0 ],
        [ 0, 0,               0,              1 ],
    ] );

    my $xz_inv = $to_xz_plane->copy;
    my $slice = $xz_inv->slice('1:3,1:3');
    $slice .= $slice->transpose;

    my $xz_to_z_axis = pdl( [
        [ 1, 0,                  0, 0                   ],
        [ 0, $z*$i_sqrtxyz,      0, -$sqrtxy*$i_sqrtxyz ],
        [ 0, 0,                  1, 0                   ],
        [ 0, $sqrtxy*$i_sqrtxyz, 0, $z*$i_sqrtxyz      ],
    ] );

    my $xzz_inv = $xz_to_z_axis->copy;
    $slice = $xzz_inv->slice('1:3,1:3');
    $slice .= $slice->transpose;
    
    my $res = $xz_to_z_axis x $to_xz_plane;
    my $res_inv = $xz_inv x $xzz_inv;
    return ($res, $res_inv);
}

=head2 boost_x

Alternative constructor to construct a specific type of Lorentz transformation:
A boost of rapidity C<eta> (C<eta = atanh(v/c)>) parallel to the x axis.

Accepts one argument: The boost's velocity divided by the speed of light
C<v/c>.

=cut

sub boost_x {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my ($b) = @_;

    my $g = 1/sqrt(1-$b**2);

    my $m = pdl([
        [$g,     -$b*$g, 0,      0      ],
        [-$b*$g, $g,     0,      0      ],
        [0,      0,      1,      0      ],
        [0,      0,      0,      1      ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}

=head2 boost_y

Alternative constructor to construct a specific type of Lorentz transformation:
A boost of rapidity C<eta> (C<eta = atanh(v/c)>) parallel to the y axis.

Accepts one argument: The boost's velocity divided by the speed of light
C<v/c>.

=cut

sub boost_y {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my ($b) = @_;

    my $g = 1/sqrt(1-$b**2);

    my $m = pdl([
        [$g,     0,      -$b*$g, 0      ],
        [0,      1,      0,      0      ],
        [-$b*$g, 0,      $g,     0      ],
        [0,      0,      0,      1      ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}

=head2 boost_z

Alternative constructor to construct a specific type of Lorentz transformation:
A boost of rapidity C<eta> (C<eta = atanh(v/c)>) parallel to the z axis.

Accepts one argument: The boost's velocity divided by the speed of light
C<v/c>.

=cut

sub boost_z {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my ($b) = @_;

    my $g = 1/sqrt(1-$b**2);

    my $m = pdl([
        [$g,     0,      0,      -$b*$g ],
        [0,      1,      0,      0      ],
        [0,      0,      1,      0      ],
        [-$b*$g, 0,      0,      $g     ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}


=head2 parity

Returns the parity operation, that is, space inversion.

=cut

sub parity {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my $m = pdl([
        [1,      0,      0,      0      ],
        [0,      -1,     0,      0      ],
        [0,      0,      -1,     0      ],
        [0,      0,      0,      -1     ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}

=head2 time_reversal

Returns the time reversal operation.

=cut

sub time_reversal {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my $m = pdl([
        [-1,     0,      0,      0      ],
        [0,      1,      0,      0      ],
        [0,      0,      1,      0      ],
        [0,      0,      0,      1      ],
    ]);

    # 0,0,0,0
    my $vec = Physics::Lorentz::Vector->new();

    return($class->new($m, $vec));
}

=head1 OTHER METHODS

=head2 merge

Merge two transformations into one. Mathematically speaking, if
C<a> is the current transformation, C<b> is another, and C<v> is
a Lorentz vector,
C<$a-E<gt>merge($b)> is the transformation C<v' = a x (b x v)>.
In words, if applied to a vector, the merged transformation is the
subsequent application of tranformation
C<b> and then C<a>.

=cut

sub merge {
    my $self = shift;
    my $trafo = shift;

    # FIXME We're breaking encapsulation of ::Vector here.
    return ref($self)->new(
        $self->{matrix} x $trafo->{matrix},
        $self->{vector}{pdl} + ($self->{matrix} x $trafo->{vector}{pdl}),
    );
}

=head2 apply

Apply transformation to a Lorentz vector or something that can be
converted into a C<Physics::Lorentz::Vector>. Returns a vector.

=cut

sub apply {
    my $self = shift;
    my $vec = shift;
    $vec = Physics::Lorentz::Vector->new($vec)
      if not _INSTANCE($vec, 'Physics::Lorentz::Vector');
    return(
        Physics::Lorentz::Vector->new(
            ($self->{matrix} x $vec->{pdl}) + $self->{vector}{pdl}
        )
    );
}

=head2 clone

Returns a copy of the object.

=cut

sub clone {
    my $self = shift;
    my $new = {};
    $new->{matrix} = $self->{matrix}->new();
    $new->{vector} = $self->{vector}->new();
    return bless($new, ref($self));
}

=head2 stringify

Returns a string representation of the object. Currently, this is
the string representation of the internal PDL vector/matrix.

=cut

sub stringify {
    my $self = shift;
    return "\nMatrix: ".$self->{matrix}."Vector: ".$self->{vector};
}



=head1 ACCESSORS

=head2 get_matrix

Returns the 4x4 PDL that represents the I<Lorentz> transformation.

This is the actual object that is used inside the Transformation object,
so be aware that modifying it results in action at a distance!

=cut

sub get_matrix { $_[0]->{matrix} }

=head2 get_vector

Returns the Physics::Lorentz::Vector object that is used inside the
Transformation object. As with the matrix, this is the actual object. Same
caveats.

Note that this isn't a PDL but a Physics::Lorentz::Vector object.

=cut

sub get_vector { $_[0]->{vector} }


# Overloaded Interface

sub _overload_multiply {
    my ($trafo, $obj, $reverse) = @_;
    ($trafo, $obj) = ($obj, $trafo) if $reverse;

    if (_INSTANCE($obj, __PACKAGE__)) {
        my $res = $trafo->merge($obj);
        if (not defined $reverse) {
            # *=
            $trafo->{matrix} = $res->{matrix};
            $trafo->{vector} = $res->{vector};
            return $trafo;
        }
        else {
            return $res;
        }
    }
    elsif (_INSTANCE($obj, 'Physics::Lorentz::Vector')) {
        croak('Assignment version of * does not make sense when a transformation is applied to a vector')
          if not defined $reverse;
        return $trafo->apply($obj);
    }
    else {
        croak('Cannot apply transformation to object of type '.(ref($obj)||''));
    }
}

1;
__END__


=head1 SEE ALSO

L<PDL>, L<Physics::Lorentz>, L<Physics::Lorentz::Vector>,

=head1 AUTHOR

Steffen Müller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Steffen Müller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
