package Panotools::Matrix;

=head1 NAME

Panotools::Matrix - Miscellaneous math for panoramic images

=head1 SYNOPSIS

$matrix = rollpitchyaw2matrix ($roll, $pitch, $yaw);

All angles are in radians not degrees.

=head1 DESCRIPTION

rollpitchyaw2matrix returns a matrix arrayref that encapsulates a
transformation suitable for rotating a vector/point by three degrees of freedom
(roll, pitch and yaw).

roll is positive rotation around the x-axis

pitch is negative rotation around the y-axis

yaw is negative rotation around the z axis

=head1 USAGE

use Panotools::Matrix qw(matrix2rollpitchyaw rollpitchyaw2matrix multiply);

my $point  = [[$x1], [$y1], [$z1]];

my $matrix = rollpitchyaw2matrix ($roll, $pitch, $yaw);

my $result = multiply ($matrix, $point);

($x2, $y2, $z2) = ($result->[0][0], $result->[1][0], $result->[2][0]);

=cut

use Math::Trig;
use Math::Trig ':radial';
use strict;
use warnings;

use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(rollpitchyaw2matrix matrix2rollpitchyaw multiply); 

sub rollpitchyaw2matrix {
    my ($roll, $pitch, $yaw) = @_;

    my $cosr = cos ($roll);
    my $sinr = sin ($roll);
    my $cosp = cos ($pitch);
    my $sinp = sin (0 - $pitch);
    my $cosy = cos ($yaw);
    my $siny = sin (0 - $yaw);

    my $rollm  = [[        1,       0,       0 ],
                  [        0,   $cosr,-1*$sinr ],
                  [        0,   $sinr,   $cosr ]];

    my $pitchm = [[    $cosp,       0,   $sinp ],
                  [        0,       1,       0 ],
                  [ -1*$sinp,       0,   $cosp ]];

    my $yawm   = [[    $cosy,-1*$siny,       0 ],
                  [    $siny,   $cosy,       0 ],
                  [        0,       0,       1 ]];

    my $foo = multiply ($yawm, $pitchm);
    multiply ($foo, $rollm);
}

sub transpose
{
    my $matrix_in = shift;
    my $matrix_out;

    my $n = 0;
    for my $row (@{$matrix_in})
    {
        my $m = 0;
        for my $column (@{$row})
        {
            $matrix_out->[$m]->[$n] = $matrix_in->[$n]->[$m];
            $m++;
        }
        $n++;
    }
    return $matrix_out;
}

sub multiply
{
    my $matrix_a = shift;
    my $transposed_b = transpose (shift);
    my $matrix_out;

    return undef if (scalar @{$matrix_a->[0]} != scalar @{$transposed_b->[0]});
    for my $row (@{$matrix_a})
    {
        my $rescol = [];
        for my $column (@{$transposed_b})
        {
            push (@{$rescol}, vekpro ($row, $column));
        }
        push (@{$matrix_out}, $rescol);
    }
    return $matrix_out;
}

sub vekpro
{
    my ($a, $b) = @_;
    my $result = 0;

    for my $i (0 .. scalar @{$a} - 1)
    {
        $result += $a->[$i] * $b->[$i];
    }
    $result;
}

# following copied from a spreadsheet by Stuart Milne

sub matrix2rollpitchyaw
{
    my $matrix = shift;
    my $roll = atan2 ($matrix->[2]->[1], $matrix->[2]->[2]);
    my $pitch = -1 * asin (-1 * $matrix->[2]->[0]);
    my $yaw = atan2 (-1 * $matrix->[1]->[0], $matrix->[0]->[0]);
    return ($roll, $pitch, $yaw);
}

1;

