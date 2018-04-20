package Pcore::Captcha::Generator;

use Pcore -const;
use Imager;
use Imager::Matrix2d;

const our $PI => 4 * CORE::atan2( 1, 1 );

# 'BorzoiRegular.ttf', 'Carlisle_Regular.ttf', 'Pixochrome.ttf', 'VenetiaMonitor.ttf', 'Piracy.ttf'
our $FONTS = [ 'RecaptchaFont.ttf', 'Cat_Women.ttf', 'Rebucked.ttf' ];

sub generate {
    my %options = (
        type      => 'png',
        text      => undef,
        angle     => undef,
        max_angle => 30,        # if angle is not defined - use this value as interval from positive to negative values to get random angle
        rotate    => 0,         # if rotate TRUE - all string will be rotated to angel, else every symbol will be rotated
        width     => 300,
        height    => 100,
        padding_x => 10,
        padding_y => 10,
        fg_color  => 'black',
        bg_color  => 'white',
        fonts     => $FONTS,
        @_,
    );

    my $task             = {};
    my @fonts_keys       = @{ $options{fonts} };
    my @words            = split /\s/sm, $options{text};
    my $width_per_symbol = ( $options{width} - $options{padding_x} * 2 ) / length $options{text};

    $task->{1}->{text} = @words == 1 ? shift @words : join( q[ ], splice( @words, 0, ( rand( @words - 1 ) + 1 ) ) );
    $task->{1}->{font} = $fonts_keys[ rand @fonts_keys ];
    $task->{1}->{left} = $options{padding_x};

    if (@words) {
        $task->{2}->{text} = q[ ] . join q[ ], @words;

        @fonts_keys = grep { $_ ne $task->{1}->{font} } @fonts_keys if @fonts_keys > 1;
        $task->{2}->{font} = $fonts_keys[ rand @fonts_keys ];
        $task->{2}->{left} = $options{width} - $options{padding_x} - int( $width_per_symbol * length( $task->{2}->{text} ) );
    }

    for my $t ( keys %{$task} ) {
        $task->{$t}->{angle}     = $options{angle} || ( rand(1) > 0.5 ? -1 : 1 ) * int( rand( $options{max_angle} ) );
        $task->{$t}->{font_size} = 1000;
        $task->{$t}->{width}     = int( $width_per_symbol * length( $task->{$t}->{text} ) );
        $task->{$t}->{height}    = $options{height} - $options{padding_y} * 2;
        $task->{$t}->{font_obj}  = Imager::Font->new( file => $ENV->{share}->get( 'www/static/fonts/' . $task->{$t}->{font} ), type => 'ft2' ) or die Imager->errstr;
        $task->{$t}->{matrix}    = $options{rotate} ? Imager::Matrix2d->rotate( degrees => $task->{$t}->{angle} ) : Imager::Matrix2d->shear( x => sin( $task->{$t}->{angle} * ( $PI / 180 ) ) / cos( $task->{$t}->{angle} * ( $PI / 180 ) ) );
        $task->{$t}->{font_obj}->transform( matrix => $task->{$t}->{matrix} );
    }

    for my $t ( keys %{$task} ) {
        my $bbox = $task->{$t}->{font_obj}->bounding_box( string => $task->{$t}->{text}, size => $task->{$t}->{font_size} );
        my $dim = _transformed_bounds( $bbox, $task->{$t}->{matrix} );

        my $rx = $task->{$t}->{width} / $dim->{width};
        my $ry = $task->{$t}->{height} / $dim->{height};
        my $k  = $rx < $ry ? $rx : $ry;
        $task->{$t}->{font_size} *= $k;

        my $bbox1 = $task->{$t}->{font_obj}->bounding_box( string => $task->{$t}->{text}, size => $task->{$t}->{font_size} );
        my $dim1 = _transformed_bounds( $bbox1, $task->{$t}->{matrix} );

        $task->{$t}->{_width}  = $dim1->{width};
        $task->{$t}->{_height} = $dim1->{height};
        $task->{$t}->{_left}   = $dim1->{left};
        $task->{$t}->{_top}    = $dim1->{top};
    }

    my $img = Imager->new( xsize => $options{width}, ysize => $options{height} )->box( filled => 1, color => $options{bg_color} );

    for my $t ( keys %{$task} ) {
        $img->string(
            text  => $task->{$t}->{text},
            x     => $task->{$t}->{_left} + $task->{$t}->{left},
            y     => $task->{$t}->{_top} + $options{padding_y} + rand( $task->{$t}->{height} - $task->{$t}->{_height} ),
            color => $options{fg_color},
            font  => $task->{$t}->{font_obj},
            size  => $task->{$t}->{font_size},
            aa    => 1
        );
    }

    my $data;
    $img->write( data => \$data, type => $options{type} );
    return \$data;
}

sub _transformed_bounds {
    my ( $bbox, $matrix ) = @_;

    my $bounds;
    for my $point ( [ $bbox->start_offset, $bbox->ascent ], [ $bbox->start_offset, $bbox->descent ], [ $bbox->end_offset, $bbox->ascent ], [ $bbox->end_offset, $bbox->descent ] ) {
        $bounds = _add_bound( $bounds, _transform_point( @{$point}, $matrix ) );
    }

    my ( $left, $miny, $right, $maxy ) = @{$bounds};
    my ( $top, $bottom ) = ( -$maxy, -$miny );
    my ( $width, $height ) = ( $right - $left, $bottom - $top );

    return {
        width  => $width,
        height => $height,
        left   => -$left,
        top    => -$top,
    };
}

sub _add_bound {
    my ( $bounds, $x, $y ) = @_;

    $bounds || return [ $x, $y, $x, $y ];

    $x < $bounds->[0] and $bounds->[0] = $x;
    $y < $bounds->[1] and $bounds->[1] = $y;
    $x > $bounds->[2] and $bounds->[2] = $x;
    $y > $bounds->[3] and $bounds->[3] = $y;

    return $bounds;
}

sub _transform_point {
    my ( $x, $y, $matrix ) = @_;

    return ( $x * $matrix->[0] + $y * $matrix->[1] + $matrix->[2], $x * $matrix->[3] + $y * $matrix->[4] + $matrix->[5] );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | NamingConventions::ProhibitAmbiguousNames                                                                      |
## |      | 101, 103             | * Ambiguously named variable "left"                                                                            |
## |      | 101, 103             | * Ambiguously named variable "right"                                                                           |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 34, 47               | CodeLayout::ProhibitParensWithBuiltins - Builtin function called with parentheses                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
