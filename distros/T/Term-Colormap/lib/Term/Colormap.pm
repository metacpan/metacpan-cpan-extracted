package Term::Colormap;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Exporter 'import';
use Scalar::Util qw( looks_like_number );

our $VERSION = '0.19';

our @EXPORT_OK = qw(
    add_mapping
    color2rgb
    color_table
    colorbar
    colored
    colored_text
    colormap
    colormap_names
    print_colored
    print_colored_text
    rgb2color
);

my $color_mapping = {};

# http://www.calmar.ws/vim/256-xterm-24bit-rgb-color-chart.html
$color_mapping->{rainbow} = [
    1,    # Red
    196, 202, 208, 214, 220, 226,
    11,   # Yellow
    190, 154, 118,  82,  46,
    10,   # Green
    47,   48,  49,  50,  51,
    14,   # Cyan
    45,   39,  33,  27,  21,
    12,   # Blue
    57,   93, 129, 165, 201,
    5,    # Magenta
];

$color_mapping->{primary} = [
    # Black, Red, Green, Yellow, Blue, Magenta, Cyan, Off-White
    0,1,2,3,4,5,6,7
];

$color_mapping->{bright} = [
    # Gray, Bright Red, Bright Green, Bright Yellow,
    8,9,10,11,
    # Bright Blue, Bright Magenta, Bright Cyan, White
    12,13,14,15
];

$color_mapping->{ash} = [
    # Black <--------------------------------> Gray
    232,233,234,235,236,237,238,239,240,241,242,243,
];

$color_mapping->{snow} = [
    # Gray <--------------------------------> White
    244,245,246,247,248,249,250,251,252,253,254,255,
];

$color_mapping->{gray} = [ @{ $color_mapping->{ash} }, @{ $color_mapping->{snow} } ];

$color_mapping->{'blue-cyan-green'} = [
    # Blue <------------------ Cyan -----------------> Green
    17,18,19,20,21,27,33,39,45,51,50,49,48,47,46,40,34,28,22
];

$color_mapping->{'red-pink-yellow'} = [
    # Red <------------------ Pink ------------------------> Yellow
    196,197,198,199,200,201,207,213,219,225,231,230,229,228,227,226
];

$color_mapping->{'green-orange-pink-blue'} = [
    # Green <-------- Orange -------- Pink --------------> Blue
    28,64,100,136,172,208,209,210,211,212,213,177,141,105,69,33
];

# 0-255
my $color2rgb = [
    '000000', '800000', '008000', '808000', '000080', '800080',
    '008080', 'c0c0c0', '808080', 'ff0000', '00ff00', 'ffff00',
    '0000ff', 'ff00ff', '00ffff', 'ffffff', '000000', '00005f',
    '000087', '0000af', '0000d7', '0000ff', '005f00', '005f5f',
    '005f87', '005faf', '005fd7', '005fff', '008700', '00875f',
    '008787', '0087af', '0087d7', '0087ff', '00af00', '00af5f',
    '00af87', '00afaf', '00afd7', '00afff', '00d700', '00d75f',
    '00d787', '00d7af', '00d7d7', '00d7ff', '00ff00', '00ff5f',
    '00ff87', '00ffaf', '00ffd7', '00ffff', '5f0000', '5f005f',
    '5f0087', '5f00af', '5f00d7', '5f00ff', '5f5f00', '5f5f5f',
    '5f5f87', '5f5faf', '5f5fd7', '5f5fff', '5f8700', '5f875f',
    '5f8787', '5f87af', '5f87d7', '5f87ff', '5faf00', '5faf5f',
    '5faf87', '5fafaf', '5fafd7', '5fafff', '5fd700', '5fd75f',
    '5fd787', '5fd7af', '5fd7d7', '5fd7ff', '5fff00', '5fff5f',
    '5fff87', '5fffaf', '5fffd7', '5fffff', '870000', '87005f',
    '870087', '8700af', '8700d7', '8700ff', '875f00', '875f5f',
    '875f87', '875faf', '875fd7', '875fff', '878700', '87875f',
    '878787', '8787af', '8787d7', '8787ff', '87af00', '87af5f',
    '87af87', '87afaf', '87afd7', '87afff', '87d700', '87d75f',
    '87d787', '87d7af', '87d7d7', '87d7ff', '87ff00', '87ff5f',
    '87ff87', '87ffaf', '87ffd7', '87ffff', 'af0000', 'af005f',
    'af0087', 'af00af', 'af00d7', 'af00ff', 'af5f00', 'af5f5f',
    'af5f87', 'af5faf', 'af5fd7', 'af5fff', 'af8700', 'af875f',
    'af8787', 'af87af', 'af87d7', 'af87ff', 'afaf00', 'afaf5f',
    'afaf87', 'afafaf', 'afafd7', 'afafff', 'afd700', 'afd75f',
    'afd787', 'afd7af', 'afd7d7', 'afd7ff', 'afff00', 'afff5f',
    'afff87', 'afffaf', 'afffd7', 'afffff', 'd70000', 'd7005f',
    'd70087', 'd700af', 'd700d7', 'd700ff', 'd75f00', 'd75f5f',
    'd75f87', 'd75faf', 'd75fd7', 'd75fff', 'd78700', 'd7875f',
    'd78787', 'd787af', 'd787d7', 'd787ff', 'd7af00', 'd7af5f',
    'd7af87', 'd7afaf', 'd7afd7', 'd7afff', 'd7d700', 'd7d75f',
    'd7d787', 'd7d7af', 'd7d7d7', 'd7d7ff', 'd7ff00', 'd7ff5f',
    'd7ff87', 'd7ffaf', 'd7ffd7', 'd7ffff', 'ff0000', 'ff005f',
    'ff0087', 'ff00af', 'ff00d7', 'ff00ff', 'ff5f00', 'ff5f5f',
    'ff5f87', 'ff5faf', 'ff5fd7', 'ff5fff', 'ff8700', 'ff875f',
    'ff8787', 'ff87af', 'ff87d7', 'ff87ff', 'ffaf00', 'ffaf5f',
    'ffaf87', 'ffafaf', 'ffafd7', 'ffafff', 'ffd700', 'ffd75f',
    'ffd787', 'ffd7af', 'ffd7d7', 'ffd7ff', 'ffff00', 'ffff5f',
    'ffff87', 'ffffaf', 'ffffd7', 'ffffff', '080808', '121212',
    '1c1c1c', '262626', '303030', '3a3a3a', '444444', '4e4e4e',
    '585858', '626262', '626262', '767676', '808080', '8a8a8a',
    '949494', '9e9e9e', 'a8a8a8', 'b2b2b2', 'bcbcbc', 'c6c6c6',
    'd0d0d0', 'dadada', 'e4e4e4', 'eeeeee',
];

my $color = 0;
my $rgb2color = { map { $_ => $color++ } @$color2rgb };

sub add_mapping {
    my ($name, $mapping) = @_;
    $color_mapping->{$name} = $mapping;
}

sub rgb2color {
    my ($rgb) = @_;

    my $original_rgb = $rgb;
    $rgb =~ s|^#||;
    $rgb = lc($rgb);
    if ( $rgb =~ m|[^a-f0-9]| ) {
        die "Invalid RGB color '$original_rgb'"
    }

    unless (defined $rgb2color->{$rgb}) {
        $rgb2color->{ $rgb } = $rgb2color->{ _get_nearest_color($rgb) };
    }

    return $rgb2color->{$rgb};
}

sub _get_nearest_color {
    my ($rgb) = @_;
    my $closest = 3 * (scalar @$color2rgb);
    my $best_color;
    for my $color ( @$color2rgb ) {
        my $dist = _color_distance($rgb, $color);
        if ($dist < $closest) {
            $best_color = $color;
            $closest = $dist;
        }
    }
    return $best_color;
}

sub _color_distance {
    my ($rgb0, $rgb1) = @_;
    my $rgb = $rgb0 . $rgb1;
    my ($r0, $g0, $b0,
        $r1, $g1, $b1) = map { hex } ( $rgb =~ m/../g );
    return abs($r1 - $r0)
         + abs($g1 - $g0)
         + abs($b1 - $b0);
}

sub colormap {
    my ($name) = @_;

    if ( exists $color_mapping->{ lc($name) } ) {
         return $color_mapping->{ lc($name) };
    }

    die "Invalid colormap name : '$name'\n" .
        "Choose one of ( " . ( join ", ", sort keys %$color_mapping ) . " )\n";

}

sub colormap_names {

    return sort keys %$color_mapping;

}

sub color2rgb {
    my ($color) = @_;

    if ($color < 0 or $color >= scalar @$color2rgb) {
        die "Invalid color value : $color";
    }

    return $color2rgb->[$color];
}


sub colorbar {
    my ($colors, $width, $orientation ) = @_;

    $width ||= 2;
    $orientation ||= 'h'; # Horizontal

    for my $color (@$colors) {
        print_colored( $color, ' 'x$width );
        unless ('h' eq substr(lc($orientation),0,1)) {
            print "\n";
        }
    }
    print "\n";
}

sub color_table {
    my ($name) = @_;
    my $mapping = colormap($name);

    my $header = "color     number   rgb";
    my $indent = (length($header) - length($name) - 1) / 2; # spaces around name

    my $ii = int($indent);
    print '-'x$ii . " $name " . '-'x$ii;
    print '-' if ($ii < $indent);
    print "\n";

    print $header . "\n";
    for my $color (@$mapping) {
        print_colored($color, ' 'x8 );
        print sprintf("   %3d   ", $color) . color2rgb($color) . "\n";
    }
    print "\n";
}

sub print_colored {
    my ($color, $txt) = @_;
    _print_with_color('bg',$color,$txt);
}

sub print_colored_text {
    my ($color, $txt) = @_;
    _print_with_color('fg',$color,$txt);
}

sub _print_with_color {
    my ($bg_or_fg, $color, $txt) = @_;
    print _get_colored_string($bg_or_fg, $color, $txt);
}

sub colored {
    my ($color, $txt) = @_;
    return _get_colored_string('bg', $color, $txt)
}

sub colored_text {
    my ($color, $txt) = @_;
    return _get_colored_string('fg', $color, $txt)
}

sub _get_colored_string {
    my ($bg_or_fg, $color, $txt) = @_;

    my $code = $bg_or_fg eq 'fg' ? 38 : 48;
    return "\x1b[${code};5;${color}m" . $txt . "\x1b[0m";
}

1; # End of Term::Colormap

__END__

=head1 NAME

Term::Colormap - Colormaps for ANSI 256 Color Terminals!

=for html
<a href="http://travis-ci.org/xxfelixxx/perl-term-colormap"><img alt="Build Status" src="https://secure.travis-ci.org/xxfelixxx/perl-term-colormap.svg" /></a>
<a href="https://coveralls.io/github/xxfelixxx/perl-term-colormap?branch=master"><img alt="Coverage Status" src="https://coveralls.io/repos/github/xxfelixxx/perl-term-colormap/badge.svg?branch=master" /></a>
<a href="https://metacpan.org/pod/Term::Colormap"><img alt="CPAN Version" src="https://badge.fury.io/pl/Term-Colormap.svg" /></a>

=head1 VERSION

Version 0.19

=head1 SYNOPSIS

Provide colormaps and functions to simplify rendering colored text using ANSI 256 colors.

    use Term::Colormap qw( colormap colorbar print_colored );

    my $rainbow = colormap('rainbow');

    colorbar($rainbow);

    print_colored( $rainbow->[3], "orange" )';

=head1 EXPORT

    add_mapping
    color2rgb
    color_table
    colorbar
    colored
    colored_text
    colormap
    colormap_names
    print_colored
    print_colored_text
    rgb2color

=head1 SUBROUTINES/METHODS

=head2 add_mapping

    Add custom colormaps to the list of available colormaps.

    add_mapping('my_colors', [ 1, 3, 5, 7, 9 ])

    color_table('my_colors');

=head2 color2rgb

    Returns rgb value for a color value.

    my $rgb = color2rgb( 255 ); #eeeeee  Very Light Gray

=head2 color_table

    Print color table (color, number, rgb) for a colormap.

    my $rainbow = colormap('rainbow');

    color_table($rainbow);

=head2 colorbar

    Print a colorbar for a colormap.

    my $rainbow = colormap('rainbow');

    colorbar($rainbow);          # Prints horizontal colorbar,  2 characters wide per color
    colorbar($rainbow, 3);       # Prints horizontal colorbar,  3 characters wide per color
    colorbar($rainbow, 10, 'v'); # Prints   vertical colorbar, 10 characters wide per color

=head2 colored

    Returns a background colored string which can be printed.

    my $colorful_string = colored( $rainbow->[3], "Text with orange background" );

    print $colorful_string . "\n";

=head2 colored_text

    Returns a colored string which can be printed.

    my $colorful_string = colored( $rainbow->[3], "Orange Text" );

    print $colorful_string . "\n";

=head2 colormap

    A colormap is an ordered set of color values (0-255).

    Returns a colormap as an Array Reference.

    See AVAILABLE COLORMAPS for colormap names.

    my $rainbow = colormap('rainbow');

    my $ash = colormap('ash');

=head2 colormap_names

    Returns the list of available colormaps.

    my @available_colormaps = colormap_names();

=head2 print_colored

    Print text using a background color.

    my $rainbow = colormap('rainbow');

    print_colored( $rainbow->[3], "Text with orange background" );

=head2 print_colored_text

    Print colored text.

    my $rainbow = colormap('rainbow');

    print_colored_text( $rainbow->[3], "Orange Text" );

=head2 rgb2color

    Returns color value for an rgb color

    my $color = rgb2color( 'eeeeee' ); 255  Very Light Gray

=head1 AVAILABLE COLORMAPS

    rainbow - 32 colors : Red -> Orange -> Yellow -> Green -> Cyan -> Blue -> Magenta

    primary -  8 colors : Black, Red, Green, Yellow, Blue, Magenta, Cyan, Off-White

    bright  -  8 colors : Gray, Bright Red, Bright Green, Bright Yellow,
                          Bright Blue, Bright Magenta, Bright Cyan, White

    ash     - 12 colors : Black -> Gray

    snow    - 12 colors : Gray  -> White

    gray    - 24 colors : Black -> Gray -> White


    blue-cyan-green        - 19 colors : Blue -> Cyan -> Green

    red-pink-yellow        - 16 colors : Red -> Pink -> Yellow

    green-orange-pink-blue - 16 colors : Green -> Orange -> Pink -> Blue

=head1 What do they look like?

    Run the show_colormap script to display them in your terminal.

=head1 AUTHOR

Felix Tubiana, C<< <felixtubiana at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-term-colormap at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-Colormap>.
I will be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Colormap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-Colormap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Term-Colormap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Term-Colormap>

=item * Search CPAN

L<http://search.cpan.org/dist/Term-Colormap/>

=back


=head1 ACKNOWLEDGEMENTS

Inspired by Term::ANSIColor


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Felix Tubiana.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
