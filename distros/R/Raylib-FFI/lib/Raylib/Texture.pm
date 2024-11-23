use 5.38.0;
use experimental qw(class);

class Raylib::Image {
    use Raylib::FFI;
    use builtin qw(false);

    field $image : param;

    field $x : param = 0;
    field $y : param = 0;

    ADJUST {
        unless ( $image isa Rayli::FFI::Image ) {
            if ( ref $image eq 'SCALAR' ) {
                $image = LoadImageFromMemory($image);
            }
            else {
                $image = LoadImage($image);
            }
        }
        unless ( IsImageReady($image) ) {
            die "Failed to load image";
        }
    }

    method as_texture() {
        Raylib::Texture->new( texture => LoadTextureFromImage($image) );
    }

    method draw ( $x = $x, $y = $y ) {
        $self->as_texture->draw( $x, $y );
    }

    method DESTROY {
        UnloadImage($image);
    }
}

class Raylib::Texture {
    use Raylib::FFI;
    use Raylib::Color;

    field $texture : param;

    field $x : param    = 0;
    field $y : param    = 0;
    field $tint : param = WHITE;

    ADJUST {
        unless ( $texture isa Raylib::FFI::Texture ) {
            $texture = LoadTexture($texture);
        }
        unless ( IsTextureReady($texture) ) {
            die "Failed to load texture";
        }
    }

    method x()      { $x }
    method y()      { $y }
    method height() { $texture->height }
    method width()  { $texture->width }

    method pos_vector() {
        Raylib::FFI::Vector2D->new( x => $x, y => $y );
    }

    method move ( $dx, $dy ) {
        $x += $dx;
        $y += $dy;
    }

    method draw ( $x = $x, $y = $y, $tint = $tint ) {
        DrawTexture( $texture, $x, $y, $tint );
    }

    method draw_rectangle ( $rect, $x = $x, $y = $y, $tint = $tint ) {
        my $pos = Raylib::FFI::Vector2D->new( x => $x, y => $y );
        DrawTextureRec( $texture, $rect, $pos, $tint );
    }

    method draw_pro (
        $src,
        $dst,
        $origin =
          Raylib::FFI::Vector2D->new( x => $dst->width, y => $dst->height ),
        $rot = 0,
        $tint = $tint
      )
    {
        DrawTexturePro( $texture, $src, $dst, $origin, $rot, $tint );
    }

    method DESTROY {
        if ( $texture isa Raylib::FFI::Texture ) {
            UnloadTexture($texture);
        }
    }
}
