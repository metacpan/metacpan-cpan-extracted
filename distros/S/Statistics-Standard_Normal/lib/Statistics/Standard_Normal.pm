#!/usr/local/bin/perl

use strict;
use warnings;

package Statistics::Standard_Normal;

our ($VERSION) = '1.00';

use Exporter qw(import);
our (@EXPORT_OK) = qw(z_to_pct pct_to_z);

my @_Pctile_Z_map =
  map { { pct => $_->[0], Z => $_->[1] } } (
    [ 0,     0 ],
    [ 0.5,   0.01253347 ],
    [ 1,     0.02506891 ],
    [ 1.5,   0.03760829 ],
    [ 2,     0.05015358 ],
    [ 2.5,   0.06270678 ],
    [ 3,     0.07526986 ],
    [ 3.5,   0.08784484 ],
    [ 4,     0.1004337 ],
    [ 4.5,   0.1130385 ],
    [ 5,     0.1256613 ],
    [ 5.5,   0.1383042 ],
    [ 6,     0.1509692 ],
    [ 6.5,   0.1636585 ],
    [ 7,     0.1763742 ],
    [ 7.5,   0.1891184 ],
    [ 8,     0.2018935 ],
    [ 8.5,   0.2147016 ],
    [ 9,     0.227545 ],
    [ 9.5,   0.240426 ],
    [ 10,    0.2533471 ],
    [ 10.5,  0.2663106 ],
    [ 11,    0.279319 ],
    [ 11.5,  0.2923749 ],
    [ 12,    0.3054808 ],
    [ 12.5,  0.3186394 ],
    [ 13,    0.3318533 ],
    [ 13.5,  0.3451255 ],
    [ 14,    0.3584588 ],
    [ 14.5,  0.3718561 ],
    [ 15,    0.3853205 ],
    [ 15.5,  0.3988551 ],
    [ 16,    0.4124631 ],
    [ 16.5,  0.426148 ],
    [ 17,    0.4399132 ],
    [ 17.5,  0.4537622 ],
    [ 18,    0.4676988 ],
    [ 18.5,  0.4817268 ],
    [ 19,    0.4958503 ],
    [ 19.5,  0.5100735 ],
    [ 20,    0.5244005 ],
    [ 20.5,  0.538836 ],
    [ 21,    0.5533847 ],
    [ 21.5,  0.5680515 ],
    [ 22,    0.5828415 ],
    [ 22.5,  0.5977601 ],
    [ 23,    0.612813 ],
    [ 23.5,  0.628006 ],
    [ 24,    0.6433454 ],
    [ 24.5,  0.6588377 ],
    [ 25,    0.6744898 ],
    [ 25.5,  0.6903088 ],
    [ 26,    0.7063026 ],
    [ 26.5,  0.7224791 ],
    [ 27,    0.7388468 ],
    [ 27.5,  0.755415 ],
    [ 28,    0.7721932 ],
    [ 28.5,  0.7891917 ],
    [ 29,    0.8064212 ],
    [ 29.5,  0.8238936 ],
    [ 30,    0.8416212 ],
    [ 30.5,  0.8596174 ],
    [ 31,    0.8778963 ],
    [ 31.5,  0.8964734 ],
    [ 32,    0.9153651 ],
    [ 32.5,  0.9345893 ],
    [ 33,    0.9541653 ],
    [ 33.5,  0.9741139 ],
    [ 34,    0.9944579 ],
    [ 34.5,  1.015222 ],
    [ 35,    1.036433 ],
    [ 35.5,  1.058122 ],
    [ 36,    1.080319 ],
    [ 36.5,  1.103063 ],
    [ 37,    1.126391 ],
    [ 37.5,  1.150349 ],
    [ 38,    1.174987 ],
    [ 38.5,  1.200359 ],
    [ 39,    1.226528 ],
    [ 39.5,  1.253565 ],
    [ 40,    1.281552 ],
    [ 40.5,  1.310579 ],
    [ 41,    1.340755 ],
    [ 41.5,  1.372204 ],
    [ 42,    1.405072 ],
    [ 42.5,  1.439531 ],
    [ 43,    1.475791 ],
    [ 43.5,  1.514102 ],
    [ 44,    1.554774 ],
    [ 44.5,  1.598193 ],
    [ 45,    1.644854 ],
    [ 45.5,  1.695398 ],
    [ 46,    1.750686 ],
    [ 46.5,  1.811911 ],
    [ 47,    1.880794 ],
    [ 47.5,  1.959964 ],
    [ 48,    2.053749 ],
    [ 48.5,  2.17009 ],
    [ 49,    2.326348 ],
    [ 49.5,  2.575829 ],
    [ 49.9,  3.090232 ],
    [ 49.95, 3.290527 ],
    [ 49.99, 3.719016 ],
  );

sub _transform_score {
    my ( $qty, $stype ) = @_;
    return unless defined $qty and defined $stype;
    my $dtype =
      $stype eq 'Z'
      ? 'pct'
      : ( $stype eq 'pct' ? 'Z' : undef );
    return unless defined $dtype;
    my $match = abs($qty);

    if ( $match <= $_Pctile_Z_map[0]->{$stype} ) {
        return $_Pctile_Z_map[0]->{$dtype};
    }
    elsif ( $match >= $_Pctile_Z_map[-1]->{$stype} ) {
        return $_Pctile_Z_map[-1]->{$dtype};
    }
    else {
        my $i = 0;
        $i++
          while $i < @_Pctile_Z_map
          and $_Pctile_Z_map[$i]->{$stype} < $match;

        if ( $_Pctile_Z_map[$i]->{$stype} == $match ) {
            return $_Pctile_Z_map[$i]->{$dtype};
        }
        else {
            $i--;
            my ( $lo_s, $lo_d ) = @{ $_Pctile_Z_map[$i] }{ $stype, $dtype };
            my ( $hi_s, $hi_d ) =
              @{ $_Pctile_Z_map[ $i + 1 ] }{ $stype, $dtype };
            my $frac = ( $match - $lo_s ) / ( $hi_s - $lo_s );
            return $lo_d + $frac * ( $hi_d - $lo_d );
        }
    }
}

sub z_to_pct {
    my $z = shift;
    return unless defined $z;
    my $offset = _transform_score( $z, 'Z' );
    $offset *= -1 if $z < 0;
    return 50 + $offset;
}

sub pct_to_z {
    my $pct = shift;
    return unless defined $pct;
    my $offset = _transform_score( abs( 50 - $pct ), 'pct' );
    return ( $pct < 50 ? -1 : 1 ) * $offset;
}

1;

__END__

=head1 NAME

Statistics::Standard_Normal - Z scores and percentiles using standard normal table

=head1 SYNOPSIS

  use Statistics::Standard_Normal qw/z_to_pct pct_to_z/;;

  while (defined my $z = get_z_score($name)) {
    say "$name's result was at the ", z_to_pct($z), ' percentile';
  }

  while (defined my $pct = get_percentile($name)) {
    say "$name's result had a Z score of ", pct_to_z($pct);
    say "Be careful of flattening at high percentiles!" if $pct > 98;
  }

=head1 DESCRIPTION

F<Statistics::Standard_Normal> provides convenience functions to
convert between Z scores and percentile scores using values taken from
a standard normal distribution (that is, a normal distribution with a
mean of 0 and a standard deviation of 1).  Percentile scores are often
used for informal reporting of results, since they make intuitive
sense to many readers, while Z scores are less familiar, but a better
behaved for values far from the mean.

The intent of this package is to be lightweight -- it has no
prerequisites outside the Perl core, no compiler requirement, and a small footprint
-- while providing values accurate enough for most uses.

=head2 FUNCTIONS

Two conversion functions are provided:

=over 4

=item B<z_to_pct>(I<$z>)

Returns the percentile corresponding to the Z-score I<$z>.  This is
the percentage of the area under the standard normal curve located to
the left of a vertical line at C<mean> + I<$z>.

A closed-form solution to this problem does not exist, so L</z_to_pct>
uses a rapid estimation that is generally accurate to C<0.1%> over the
range of -3.719 < I<$z> < 3.719.  Values outside this range return
C<0.01%> or C<99.99%>, depending on the sign of I<$z>.

=item B<pct_to_z>(I<$pctile>)

Returns the Z-score corresponding to I<$pctile>.  This uses an
approximation similar to the one used by L</z_to_pct>; the result is
generally accurate to C<0.005>.  Values of I<$pctile> <C<0.01> or
>C<99.9> return C<-3.719> and C<3.719>, respectively.

=back

=head2 EXPORT

Both L</pct_to_z> and L</z_to_pct> are available for importation,
but neither are exported by default.

=head1 BUGS AND CAVEATS

Conversion to Z scores of percentiles very close to 0 or 100 becomes
increasingly inaccurate, as smaller and smaller changes in percentile
are associated with a given change in Z score.

=head1 SEE ALSO

For intensive usage, a compiled library may provide better performance
(cf. L<Math::Cephes/ndtr> or L<Math::CDF> for Perl bindings to some
options). 

If you have a set of observations and want to perform statistical
tests, there are a host of modules in the C<Statistics::> namespace;
ones that may help you derive Z scores include L<Statistics::Zscore>
and L<Statistics::Zed>.

=head1 VERSION

version 1.00

=head1 AUTHOR

Charles Bailey <cbail@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2014 Charles Bailey.

This software may be used under the terms of the Artistic License or
the GNU General Public License, as the user prefers.

=head1 ACKNOWLEDGMENT

The code incorporated into this package was originally written with
United States federal funding as part of research work done by the
author at the Children's Hospital of Philadelphia.

=cut
