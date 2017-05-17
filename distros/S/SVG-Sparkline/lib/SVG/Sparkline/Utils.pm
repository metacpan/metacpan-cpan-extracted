package SVG::Sparkline::Utils;

use warnings;
use strict;
use Carp;
use List::Util;
use SVG;

our $VERSION = 1.12;

sub format_f
{
    my $val = sprintf '%.02f', $_[0];
    $val =~ s/0$//;
    $val =~ s/\.0$//;
    $val = 0 if $val eq '-0';
    return $val;
}

sub calculate_xscale
{
    my ($args, $xrange) = @_;

    if( $args->{width} )
    {
        my $dwidth = $args->{width} - 2*$args->{padx};
        $args->{xscale} = ($dwidth-1) / $xrange;
    }
    else
    {
        $args->{xscale} ||= 2;
        my $dwidth = @{$args->{values}} * $args->{xscale} - 1;
        $args->{width} = $dwidth + 2*$args->{padx};
    }
    return;
}

sub calculate_yscale_and_offset
{
    my ($args, $yrange, $offset) = @_;

    # If the data values are all 0, default the range. Any value would be
    # usable. So, I just pick 1 arbitrarily.
    $yrange ||= 1;
    my $height = $args->{height} - 2*$args->{pady};
    $args->{yscale} = -$height / $yrange;
    my $baseline = format_f( -$args->{yscale} * $offset );

    $args->{yoff} = -($baseline+$height+$args->{pady});

    return;
}

sub xypairs_to_points_str
{
    my ($vals, $xscale, $yscale) = @_;
    return join( ' ',
        map { format_f($xscale * $_->[0]) .','. format_f($yscale * $_->[1]) }
        @{$vals}
    );
}

sub summarize_values
{
    my ($array) = @_;
    my $desc = {
        min => List::Util::min( @{$array} ),
        max => List::Util::max( @{$array} ),
    };
    
    $desc->{min} = 0 if $desc->{min} > 0;
    $desc->{max} = 0 if $desc->{max} < 0;

    $desc->{range} = $desc->{max}-$desc->{min};
    return $desc;
}

sub summarize_xy_values
{
    my ($array) = @_;
    return _summarize_xy_pairs( $array ) if 'ARRAY' eq ref $array->[0];
    my $desc = {
        ymin => List::Util::min( @{$array} ),
        ymax => List::Util::max( @{$array} ),
        xmin => 0,
        xmax => $#{$array},
        xrange => $#{$array},
    };
    $desc->{base}   = 0;
    $desc->{base}   = $desc->{ymin} if $desc->{ymin} > 0;
    $desc->{base}   = $desc->{ymax} if $desc->{ymax} < 0;
    $desc->{offset} = $desc->{ymin} - $desc->{base};

    $desc->{yrange} = $desc->{ymax}-$desc->{ymin};
    my $i = 0;
    $desc->{vals} = [map { [$i++,$_-$desc->{base}] } @{$array}];
    return $desc;
}

sub _summarize_xy_pairs 
{
    my ($array) = @_;
    my $desc = {
        xmin => $array->[0]->[0],
        xmax => $array->[-1]->[0],
        ymin => $array->[0]->[1],
        ymax => $array->[0]->[1],
    };

    foreach my $p ( @{$array} )
    {
        die "Array element is not a pair.\n"
            unless 'ARRAY' eq ref $p && 2 == @{$p};
        $desc->{xmin} = $p->[0] if $p->[0] < $desc->{xmin};
        $desc->{xmax} = $p->[0] if $p->[0] > $desc->{xmax};
        $desc->{ymin} = $p->[1] if $p->[1] < $desc->{ymin};
        $desc->{ymax} = $p->[1] if $p->[1] > $desc->{ymax};
    }
    $desc->{base}   = 0;
    $desc->{base}   = $desc->{ymin} if $desc->{ymin} > 0;
    $desc->{base}   = $desc->{ymax} if $desc->{ymax} < 0;
    $desc->{offset} = $desc->{ymin} - $desc->{base};

    $desc->{xrange} = $desc->{xmax}-$desc->{xmin};
    $desc->{yrange} = $desc->{ymax}-$desc->{ymin};
    $desc->{vals} =
        [map { [$_->[0]-$desc->{xmin},$_->[1]-$desc->{base}] } @{$array}];
    return $desc;
}

sub make_svg
{
    my ($args) = @_;
    my $svg = SVG->new(
        -inline=>1, -nocredits=>1, -raiseerror=>1, -indent=>'', -elsep=>'',
        width=>$args->{width}, height=>$args->{height},
        viewBox=> join( ' ', @{$args}{qw/xoff yoff width height/} )
    );

    if( exists $args->{bgcolor} )
    {
        $svg->rect(
            x => $args->{xoff}-1, y => $args->{yoff}-1,
            width => $args->{width}+2, height => $args->{height}+2,
            stroke => 'none', fill => $args->{bgcolor}
        );
    }
    return $svg;
}

sub validate_array_param
{
    my ($args, $name) = @_;
    local $Carp::CarpLevel = 2;
    croak "Missing required '$name' parameter.\n" if !exists $args->{$name};
    croak "'$name' must be an array reference.\n" unless 'ARRAY' eq ref $args->{$name};
    croak "No values for '$name' specified.\n" unless @{$args->{$name}};
    return;
}

sub range_mark_to_index
{
    my ($type, $index, $values) = @_;
    return 0 if $index eq 'first';
    return $#{$values} if $index eq 'last';
    return $index if $index !~ /\D/ && $index < @{$values};
    if( 'high' eq $index )
    {
        my $high = $values->[0]->[1];
        my $ndx = 0;
        foreach my $i ( 1 .. $#{$values} )
        {
            ($high,$ndx) = ($values->[$i]->[1],$i) if $values->[$i]->[1] > $high;
        }
        return $ndx;
    }
    elsif( 'low' eq $index )
    {
        my $low = $values->[0]->[0];
        my $ndx = 0;
        foreach my $i ( 1 .. $#{$values} )
        {
            ($low,$ndx) = ($values->[$i]->[0],$i) if $values->[$i]->[0] < $low;
        }
        return $ndx;
    }

    croak "'$index' is not a valid mark for $type sparkline";
}

sub mark_to_index
{
    my ($type, $index, $values) = @_;
    return 0 if $index eq 'first';
    return $#{$values} if $index eq 'last';
    return $index if $index !~ /\D/ && $index < @{$values};
    if( 'high' eq $index )
    {
        my $high = $values->[0];
        my $ndx = 0;
        foreach my $i ( 1 .. $#{$values} )
        {
            ($high,$ndx) = ($values->[$i],$i) if $values->[$i] > $high;
        }
        return $ndx;
    }
    elsif( 'low' eq $index )
    {
        my $low = $values->[0];
        my $ndx = 0;
        foreach my $i ( 1 .. $#{$values} )
        {
            ($low,$ndx) = ($values->[$i],$i) if $values->[$i] < $low;
        }
        return $ndx;
    }

    croak "'$index' is not a valid mark for $type sparkline";
}


1;

__END__

=head1 NAME

SVG::Sparkline::Utils - Utility functions used by the sparkline type modules.

=head1 VERSION

This document describes SVG::Sparkline::Utils version 1.11

=head1 DESCRIPTION

This module is not intended to be used directly. It is provided to support
the different types of sparklines.

=head1 INTERFACE 

=head2 format_f

Convert numeric data to a reasonable output format for sparkline-sized SVG.
No more than 2 decimal places are displayed and all trailing zeros after
the decimal place are removed.

=head2 calculate_xscale

Given an C<SVG::Sparkline> argument hash and a range of x values, calculate
the xscaling.

The following optional values are read from C<$args>: C<width>, C<padx>,
and C<xscale>. Depending on the various values, the following values in
C<$args> may be updated: C<xscale> and C<width>.

=head2 calculate_yscale_and_offset

Given an C<SVG::Sparkline> argument hash and a range of y values, calculate
the yscaling and y offset for the graphic.

The following optional values are read from C<$args>: C<height>, C<pady>,
and C<yscale>. Depending on the various values, the following values in
C<$args> may be updated: C<yscale>, C<height>, and C<yoff>.

=head2 xypairs_to_points_str

Given a reference to an array of x, y pairs (C<$vals>) and scaling factors
(C<$xscale>, C<$yscale>), create a string appropriate for the I<points>
attribute of either an SVG C<polyline> or C<polygon> element graphing these
points.

=head2 make_svg

Create the SVG object with the proper base parameters for a sparkline. Apply
the supplied parameters as well.

=head2 summarize_values

Given a list of numeric values generate a structured summary simplifying
changes for later. Calculate I<min>, I<max>, and I<range>.

=head2 summarize_xy_values

Given a list of pairs of numeric values, generate a structured summary
simplifying changes for later. Calculate I<min>, I<max>, I<range> for the
C<x> and C<y> values supplied.

If supplied with a list of numeric values, instead of a list of pairs,
create a list of appropriate pairs and calculate the summaries as above.

=head2 validate_array_param

Validate an array parameter or throw an exception.

=head2 mark_to_index

Given the sparkline type, a mark index and a reference to an array of values,
return a numeric index representing C<$index>. Throw an exception on error.

=head2 range_mark_to_index

Given the sparkline type, a mark index and a reference to an array of high/low
pairs, return a numeric index representing C<$index>. Throw an exception on error.

=head1 DIAGNOSTICS

The diagnostics are reported where they are emitted by the library.

=head1 CONFIGURATION AND ENVIRONMENT

SVG::Sparkline::Utils requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<SVG>, L<List::Util>.

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

