package SVG::Sparkline::RangeBar;

use warnings;
use strict;
use Carp;
use SVG;
use List::Util ();
use SVG::Sparkline::Utils;

use 5.008000;
our $VERSION = 1.11;

# alias to make calling shorter.
*_f = *SVG::Sparkline::Utils::format_f;

sub valid_param {
    return scalar grep { $_[1] eq $_ } qw/gap thick/;
}

sub make
{
    my ($class, $args) = @_;
    # validate parameters
    SVG::Sparkline::Utils::validate_array_param( $args, 'values' );
    croak "'values' must be an array of pairs.\n"
        if grep { 'ARRAY' ne ref $_ || 2 != @{$_} } @{$args->{values}};
    my $vals = SVG::Sparkline::Utils::summarize_values(
        [ map { @{$_} } @{$args->{values}} ]
    );

    my $height = $args->{height} - 2*$args->{pady};
    my $yscale = -$height / $vals->{range};
    my $baseline = _f(-$yscale*$vals->{min});

    # Figure out the width I want and define the viewBox
    my $dwidth;
    my $gap = $args->{gap} || 0;
    $args->{thick} ||= 3;
    my $space = $args->{thick}+$gap;
    if($args->{width})
    {
        $dwidth = $args->{width} - $args->{padx}*2;
        $space = _f( $dwidth / @{$args->{values}} );
        $args->{thick} = $space - $gap;
    }
    else
    {
        $dwidth = @{$args->{values}} * $space;
        $args->{width} = $dwidth + 2*$args->{padx}; 
    }
    $args->{yoff} = -($baseline+$height+$args->{pady});
    $args->{xscale} = $space;
    my $svg = SVG::Sparkline::Utils::make_svg( $args );

    my $off = _f( $gap/2 );
    my $prev = 0;
    my $path = "M". _f(-$args->{thick}-$off).",0";
    foreach my $v (@{$args->{values}})
    {
        # Move from previous x,y to low value
        $path .= 'm'. _f($args->{thick}+$gap) .','. _f($yscale*($v->[0]-$prev));
        my $vert = _f( $yscale * ($v->[1]-$v->[0]) );
        if($vert)
        {
            $path .= "v${vert}h$args->{thick}v". _f(-$vert)."h-$args->{thick}";
        }
        else
        {
            $path .= _zero_height_path( $args->{thick} );
        }
        $prev = $v->[0];
    }
    $path = _clean_path( $path );
    $svg->path( stroke=>'none', fill=>$args->{color}, d=>$path );

    if( exists $args->{mark} )
    {
        _make_marks( $svg,
            thick=>$args->{thick}, off=>$off,
            space=>$space, yscale=>$yscale,
            values=>$args->{values}, mark=>$args->{mark}
        );
    }
    return $svg;
}

sub _zero_height_path
{
    my ($thick) = @_;
    my $path = 'v-0.5';
    my $step = 1;
    $step = $thick/4 if $thick <= 2;
    $step = 2 if $thick >= 8;
    my $num_steps = int( $thick/$step ) - 1;
    my $leftover = $thick-($num_steps*$step);
    foreach my $i (1 .. $num_steps)
    {
        $path .= "h${step}v" . ($i%2? 1 :-1);
    }
    $path .= "h${leftover}v". ($thick%2?0.5: -0.5) . "h-$thick";
    return $path;
}

sub _make_marks
{
    my ($svg, %args) = @_;
    
    my @marks = @{$args{mark}};
    while(@marks)
    {
        my ($index,$color) = splice( @marks, 0, 2 );
        $index = SVG::Sparkline::Utils::range_mark_to_index( 'RangeBar', $index, $args{values} );
        _make_mark( $svg, %args, index=>$index, color=>$color );
    }
    return;
}

sub _make_mark
{
    my ($svg, %args) = @_;
    my $index = $args{index};
    my ($lo, $hi) = @{$args{values}->[$index]};
    my $y = _f( $hi * $args{yscale} );
    my $h = _f( ($hi-$lo) * $args{yscale});
    if($h)
    {
        my $x = _f($index * $args{space} + $args{off});
        $svg->rect( x=>$x, y=>$y,
            width=>$args{thick}, height=>abs($h),
            stroke=>'none', fill=>$args{color}
        );
    }
    else
    {
        my $x = _f($index * $args{space} +$args{off});
        $svg->path(
            d=>"M$x,$y". _zero_height_path( $args{thick} ),
            stroke=>'none', fill=>$args{color}
        );
    }
    return;
}

sub _clean_path
{
    my ($path) = @_;
    $path =~ s/^M([-.\d]+),([-.\d]+)m([-.\d]+),([-.\d]+)/'M'. _f($1+$3) .','. _f($2+$4)/e;
    $path =~ s/h0(?![.\d])//g;
    return $path;
}

1;

__END__

=head1 NAME

SVG::Sparkline::RangeBar - Supports SVG::Sparkline for range bar graphs.

=head1 VERSION

This document describes SVG::Sparkline::RangeBar version 1.11

=head1 DESCRIPTION

Not used directly. This module provides a factory interface to build
a 'RangeBar' sparkline. It is loaded on demand by L<SVG::Sparkline>.

=head1 INTERFACE 

=head2 make

Create an L<SVG> object that represents the RangeBar style of Sparkline.

=head2 valid_param

Class method that returns true if the supplied parameter is valid for an
RangeBar Sparkline.

=head1 DIAGNOSTICS

=over

=item C<< Missing required '%s' parameter. >>

The named parameter is not supplied.

=item C<< '%s' must be an array reference. >>

The named parameter was not an array reference.

=item C<< No values for '%s' specified. >>

The supplied array has no values.

=back

=head1 CONFIGURATION AND ENVIRONMENT

SVG::Sparkline::RangeBar requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Carp>, L<SVG>, L<SVG::Sparkline::Utils>.

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

