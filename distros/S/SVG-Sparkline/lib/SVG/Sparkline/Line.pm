package SVG::Sparkline::Line;

use warnings;
use strict;
use Carp;
use SVG;
use SVG::Sparkline::Utils;

use 5.008000;
our $VERSION = 1.12;

# aliases to make calling shorter.
*_f = *SVG::Sparkline::Utils::format_f;

sub valid_param {
    return scalar grep { $_[1] eq $_ } qw/thick xrange yrange/;
}

sub make
{
    my ($class, $args) = @_;
    # validate parameters
    SVG::Sparkline::Utils::validate_array_param( $args, 'values' );
    my $valdesc = SVG::Sparkline::Utils::summarize_xy_values( $args->{values} );

    my $thick = $args->{thick} || 1;
    SVG::Sparkline::Utils::calculate_xscale( $args, $valdesc->{xrange} );
    SVG::Sparkline::Utils::calculate_yscale_and_offset( $args, $valdesc->{yrange}, $valdesc->{offset} );
    my $svg = SVG::Sparkline::Utils::make_svg( $args );

    my $points = SVG::Sparkline::Utils::xypairs_to_points_str(
        $valdesc->{vals}, $args->{xscale}, $args->{yscale}
    );
    $svg->polyline( fill=>'none', 'stroke-width'=>$thick, stroke=>$args->{color}, 'stroke-linecap'=>'round', points=>$points );

    if( exists $args->{mark} )
    {
        _make_marks( $svg,
            thick=>$thick, xscale=>$args->{xscale}, yscale=>$args->{yscale},
            values=>$valdesc->{vals}, mark=>$args->{mark}
        );
    }

    return $svg;
}

sub _make_marks
{
    my ($svg, %args) = @_;
    
    my @marks = @{$args{mark}};
    my @yvalues = map { $_->[1] } @{$args{values}};
    while(@marks)
    {
        my ($index,$color) = splice( @marks, 0, 2 );
        $index = SVG::Sparkline::Utils::mark_to_index( 'Line', $index, \@yvalues );
        _make_mark( $svg, %args, index=>$index, color=>$color );
    }
    return;
}

sub _make_mark
{
    my ($svg, %args) = @_;
    my $index = $args{index};
    my $x = _f($args{xscale} * $args{values}->[$index]->[0]);
    my $y = _f($args{yscale} * $args{values}->[$index]->[1]);
    $svg->circle( cx=>$x, cy=>$y, r=>$args{thick},
        stroke=>'none', fill=>$args{color}
    );
    return;
}

1;

__END__

=head1 NAME

SVG::Sparkline::Line - Supports SVG::Sparkline for line graphs.

=head1 VERSION

This document describes SVG::Sparkline::Line version 1.11

=head1 DESCRIPTION

Not used directly. This module provides a factory interface to build
a 'Line' sparkline. It is loaded on demand by L<SVG::Sparkline>.

=head1 INTERFACE 

=head2 make

Create an L<SVG> object that represents the Line style of Sparkline.

=head2 valid_param

Class method that returns true if the supplied parameter is valid for an
Line Sparkline.

=head1 DIAGNOSTICS

=over

=item C<< Missing required '%s' parameter. >>

The named parameter is not supplied.

=item C<< '%s' must be an array reference. >>

The named parameter was not an array reference.

=item C<< No values for '%s' specified. >>

The supplied array has no values.

=item C<< Count of 'x' and 'y' values must match. >>

The two arrays have different numbers of values.

=back


=head1 CONFIGURATION AND ENVIRONMENT

SVG::Sparkline::Line requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Carp>, L<SVG>, L<SVG::Sparkline::Line>.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< gwadej@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl 5.8.0. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

