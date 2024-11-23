use 5.38.0;
use builtin 'export_lexically';
use Raylib::FFI ();

package Raylib::Color {
    use Convert::Color ();

    sub rgba ( $r, $g, $b, $a = 255 ) {
        return Raylib::FFI::Color->new( r => $r, g => $g, b => $b, a => $a );
    }

    sub new ( $, $color, $a = 255 ) {
        unless ( $color isa Convert::Color ) {
            $color = Convert::Color->new($color);
        }
        return rgba( ( map { 255 * $_ } $color->rgb ), $a );
    }

    sub hsv ( $hue, $sat, $val, $alpha ) {
        __PACKAGE__->new( "hsv:$hue,$sat,$val", $alpha );
    }

    my sub htoi ($hex) { unpack( 'l', pack( 'L', hex($hex) ) ) }

    sub css ($css) {
        if ( length($css) == 4 ) {
            my ( $h, $r, $g, $b ) = map { htoi( "$_" x 2 ) if !m/#/ } split //,
              $css;
            return rgba( $r, $g, $b );
        }
        if ( length($css) == 7 ) {
            my $r = htoi( substr( $css, 1, 2 ) );
            my $g = htoi( substr( $css, 3, 2 ) );
            my $b = htoi( substr( $css, 5, 2 ) );
            return rgba( $r, $g, $b );
        }

    }

    sub rainbow ( $cycle = 0, $colors = 7, $freq = 5 / $colors, $last = 0 ) {
        return sub {
            my $r = int( sin( $freq * abs($cycle) + 0 ) * (127) + 128 );
            my $g = int( sin( $freq * abs($cycle) + 1 ) * (127) + 128 );
            my $b = int( sin( $freq * abs($cycle) + 3 ) * (127) + 128 );
            $cycle *= -1 if ++$cycle == $colors;
            return rgba( $r, $g, $b );
        }
    }

    use constant LIGHTGRAY => rgba( 200, 200, 200 );
    use constant GRAY      => rgba( 130, 130, 130 );
    use constant DARKGRAY  => rgba( 80,  80,  80 );
    use constant LIGHTGREY => rgba( 200, 200, 200 );
    use constant GREY      => rgba( 130, 130, 130 );
    use constant DARKGREY  => rgba( 80,  80,  80 );
    use constant YELLOW    => rgba( 253, 249, 0 );
    use constant GOLD      => rgba( 255, 203, 0 );
    use constant ORANGE    => rgba( 255, 161, 0 );
    use constant PINK      => rgba( 255, 109, 194 );
    use constant RED       => rgba( 230, 41,  55 );
    use constant MAROON    => rgba( 190, 33,  55 );
    use constant GREEN     => rgba( 0,   228, 48 );
    use constant LIME      => rgba( 0,   158, 47 );
    use constant DARKGREEN => rgba( 0,   117, 44 );
    use constant SKYBLUE   => rgba( 102, 191, 255 );
    use constant BLUE      => rgba( 0,   121, 241 );
    use constant DARKBLUE  => rgba( 0,   82,  172 );
    use constant PURPLE    => rgba( 200, 122, 255 );
    use constant VIOLET    => rgba( 135, 60,  190 );
    use constant DARKPURPL => rgba( 112, 31,  126 );
    use constant BEIGE     => rgba( 211, 176, 131 );
    use constant BROWN     => rgba( 127, 106, 79 );
    use constant DARKBROWN => rgba( 76,  63,  47 );

    use constant WHITE    => rgba( 255, 255, 255 );
    use constant BLACK    => rgba( 0,   0,   0 );
    use constant BLANK    => rgba( 0,   0,   0, 0 );
    use constant MAGENTA  => rgba( 255, 0,   255 );
    use constant RAYWHITE => rgba( 245, 245, 245 );

    # for easy gradient creation when debugging
    # 1D gradients
    sub REDISH   { rgb( shift() * 255, 0,             0 ) }
    sub GREENISH { rgb( 0,             shift() * 255, 0 ) }
    sub BLUISH   { rgb( 0,             0,             shift() * 255 ) }
    sub GRAYISH  { my $c = shift; rgb( $c, $c, $c ) }
    sub GREYISH  { goto &GRAYISH; }

    # 2D gradients
    sub CYANISH    { rgb( 0,             shift() * 255, shift() * 255 ) }
    sub MAGENTAISH { rgb( shift() * 255, 0,             shift() * 255 ) }
    sub YELLOWISH  { rgb( shift() * 255, shift() * 255, 0 ) }

    # 3D gradients
    sub WHITISH { rgb( shift() * 255, shift() * 255, shift() * 255 ) }

    sub import {
        export_lexically(
            LIGHTGRAY => \&LIGHTGRAY,
            GRAY      => \&GRAY,
            DARKGRAY  => \&DARKGRAY,
            LIGHTGREY => \&LIGHTGREY,
            GREY      => \&GREY,
            DARKGREY  => \&DARKGREY,
            YELLOW    => \&YELLOW,
            GOLD      => \&GOLD,
            ORANGE    => \&ORANGE,
            PINK      => \&PINK,
            RED       => \&RED,
            MAROON    => \&MAROON,
            GREEN     => \&GREEN,
            LIME      => \&LIME,
            DARKGREEN => \&DARKGREEN,
            SKYBLUE   => \&SKYBLUE,
            BLUE      => \&BLUE,
            DARKBLUE  => \&DARKBLUE,
            PURPLE    => \&PURPLE,
            VIOLET    => \&VIOLET,
            DARKPURPL => \&DARKPURPL,
            BEIGE     => \&BEIGE,
            BROWN     => \&BROWN,
            DARKBROWN => \&DARKBROWN,
            WHITE     => \&WHITE,
            BLACK     => \&BLACK,
            BLANK     => \&BLANK,
            MAGENTA   => \&MAGENTA,
            RAYWHITE  => \&RAYWHITE,

            REDISH     => \&REDISH,
            GREENISH   => \&GREENISH,
            BLUISH     => \&BLUISH,
            GRAYISH    => \&GRAYISH,
            GREYISH    => \&GREYISH,
            CYANISH    => \&CYANISH,
            MAGENTAISH => \&MAGENTAISH,
            YELLOWISH  => \&YELLOWISH,
            WHITISH    => \&WHITISH,
        );
    }
}
