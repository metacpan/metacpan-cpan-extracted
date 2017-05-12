package SVG::Sparkline::Bar;

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
    my $vals = SVG::Sparkline::Utils::summarize_values( $args->{values} );

    my $height = $args->{height} - 2*$args->{pady};
    # If we get all zeros for data, the range will be 0, and the division will
    # fail. Almost anything will be a reasonable range, so arbitrarily choose 1.
    my $yscale = -$height / ($vals->{range} || 1);
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
    my @pieces;
    foreach my $v (@{$args->{values}})
    {
        my $curr = _f( $yscale*($v-$prev) );
        my $subpath = $curr ? "v${curr}h$args->{thick}" : "h$args->{thick}";
        $prev = $v;
        if($gap && $curr)
        {
            $subpath .= 'v' . _f(-$curr);
            $prev = 0;
        }
        push @pieces, $subpath;
    }
    push @pieces, 'v' . _f( $yscale*(-$prev) ) if $prev;
    my $spacer = $gap ? "h$gap" : '';
    my $path = "M$off,0" . join( $spacer, @pieces ) . 'z';
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

sub _make_marks
{
    my ($svg, %args) = @_;
    
    my @marks = @{$args{mark}};
    while(@marks)
    {
        my ($index,$color) = splice( @marks, 0, 2 );
        $index = _check_index( $index, $args{values} );
        _make_mark( $svg, %args, index=>$index, color=>$color );
    }
    return;
}

sub _make_mark
{
    my ($svg, %args) = @_;
    my $index = $args{index};
    my $h = _f($args{values}->[$index] * $args{yscale});
    if($h)
    {
        my $x = _f($index * $args{space} + $args{off});
        my $y = $h > 0 ? 0 : $h;
        $svg->rect( x=>$x, y=>$y,
            width=>$args{thick}, height=>abs( $h ),
            stroke=>'none', fill=>$args{color}
        );
    }
    else
    {
        my $x = _f(($index+0.5) * $args{space} +$args{off});
        $svg->ellipse( cx=>$x, cy=>0, ry=>0.5, rx=>$args{thick}/2,
            stroke=>'none', fill=>$args{color}
        );
    }
    return;
}

sub _check_index
{
    return SVG::Sparkline::Utils::mark_to_index( 'Bar', @_ );
}

sub _clean_path
{
    my ($path) = @_;
    $path =~ s!((?:h[\d.]+){2,})!_consolidate_moves( $1 )!eg;
    $path =~ s/h0(?![.\d])//g;
    return $path;
}

sub _consolidate_moves
{
    my ($moves) = @_;
    my @steps = split /h/, $moves;
    shift @steps; # discard empty initial string
    return 'h' . _f( List::Util::sum( @steps ) );
}

1;

__END__

=head1 NAME

SVG::Sparkline::Bar - Supports SVG::Sparkline for bar graphs.

=head1 VERSION

This document describes SVG::Sparkline::Bar version 1.11

=head1 DESCRIPTION

Not used directly. This module provides a factory interface to build
a 'Bar' sparkline. It is loaded on demand by L<SVG::Sparkline>.

=head1 INTERFACE 

=head2 make

Create an L<SVG> object that represents the Bar style of Sparkline.

=head2 valid_param

Class method that returns true if the supplied parameter is valid for an
Bar Sparkline.

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

SVG::Sparkline::Bar requires no configuration files or environment variables.

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

