#!/usr/bin/env perl
use 5.38.0;

use lib qw(lib);
use experimental 'class';

use Raylib::App;

class Sprite {
    field $rectangle : param;

    method as_rectangle() { $rectangle }

    sub box ( $class, $x, $y, $width = 64, $height = $width ) {
        $class->new(
            rectangle => Raylib::FFI::Rectangle->new(
                x      => $x * $width,
                y      => $y * $height,
                width  => $width,
                height => $height
            )
        );
    }
}

class Tile {
    field $walkable : param;
    field $sprite_box : param;

    method as_rectangle() { $sprite_box->as_rectangle() }
    method is_walkable()  { $walkable }
}

class GameMap {
    use File::Share 'dist_file';

    field $width : param;
    field $height : param;
    field $tile_size : param;
    field $sprite_map : param;

    method is_in_bounds ( $x, $y ) {
        return 0 <= $x * $tile_size < $width * $tile_size
          && 0 <= $y * $tile_size < $height * $tile_size;
    }

    my sub floor_tile() {
        Tile->new(
            walkable   => 1,
            sprite_box => Sprite->box( 0, 19 ),
        );
    }

    field @tiles = map { [ map floor_tile(), 0 .. $width ] } 0 .. $height;

    my sub wall_tile() {
        Tile->new(
            walkable   => 0,
            sprite_box => Sprite->box( 4, 12 ),
        );
    }

    ADJUST {
        # draw a little wall in the room
        $tiles[ $height / 2 + 1 ]->@[ $width / 2 .. ( $width / 2 + 2 ) ] =
          map wall_tile(), 0 .. 2;
    }

    method draw () {
        state $i = 0;
        for my $y ( 0 .. $height ) {
            for my $x ( 0 .. $width ) {
                my $tile   = $self->tile_at( $x, $y );
                my $dst    = Sprite->box( $x, $y, $tile_size )->as_rectangle();
                my $center = Raylib::FFI::Vector2D->new(
                    x => $dst->width,
                    y => $dst->height / 2
                );
                $sprite_map->draw_pro( $tile->as_rectangle, $dst, $center, );
            }
        }
    }

    method tile_at ( $x, $y ) {
        return $tiles[$y][$x];
    }
}

class Entity {
    field $tile_size : param;
    field $texture : param;
    field $x : param;
    field $y : param;
    field $sprite_box : param;

    method x() { $x }
    method y() { $y }

    method move ( $dx, $dy ) {
        $x += $dx;
        $y += $dy;
    }

    method draw () {
        my $dst = Sprite->box( $x, $y, $tile_size )->as_rectangle;
        $texture->draw_pro( $sprite_box->as_rectangle, $dst );
    }
}

class Engine {
    use Raylib::Keyboard;
    use File::Share 'dist_file';

    field $height : param;
    field $width : param;
    field $tile_size : param = 32;

    field $app =
      Raylib::App->window( $width * $tile_size, $height * $tile_size, $0 );

    field $sprites = Raylib::Texture->new(
        texture => dist_file( 'Raylib-FFI', 'assets/tiles-64.png' ) );

    field $player = Entity->new(
        tile_size  => $tile_size,
        texture    => $sprites,
        sprite_box => Sprite->box( 0, 0 ),
        x          => $width / 2,
        y          => $height / 2,
    );

    field @npcs = (
        Entity->new(
            tile_size  => $tile_size,
            texture    => $sprites,
            sprite_box => Sprite->box( 7, 1 ),
            x          => $player->x - 3,
            y          => $player->y - 3,
        ),
    );

    field $map = GameMap->new(
        width      => $width,
        height     => $height,
        tile_size  => $tile_size,
        sprite_map => $sprites,
    );

    field $keyboard;

    ADJUST {
        $app->fps(60);

        my sub movement_action ( $dx, $dy ) {
            my ( $x, $y ) = ( $player->x + $dx, $player->y + $dy );
            return unless $map->is_in_bounds( $x, $y );
            return unless $map->tile_at( $x, $y )->is_walkable;
            $player->move( $dx, $dy );
        }

        $keyboard = Raylib::Keyboard->new(

            key_map => {

                # vim keys
                KEY_H() => sub { movement_action( -1, 0 ) },
                KEY_L() => sub { movement_action( 1,  0 ) },
                KEY_K() => sub { movement_action( 0,  -1 ) },
                KEY_J() => sub { movement_action( 0,  1 ) },

                # wasd keys
                KEY_W() => sub { movement_action( 0,  -1 ) },
                KEY_S() => sub { movement_action( 0,  1 ) },
                KEY_A() => sub { movement_action( -1, 0 ) },
                KEY_D() => sub { movement_action( 1,  0 ) },

                # arrow keys
                KEY_UP()    => sub { movement_action( 0,  -1 ) },
                KEY_DOWN()  => sub { movement_action( 0,  1 ) },
                KEY_LEFT()  => sub { movement_action( -1, 0 ) },
                KEY_RIGHT() => sub { movement_action( 1,  0 ) },
            },
        )
    }

    method run() {
        while ( !$app->exiting ) {
            $keyboard->handle_events();
            $app->clear();
            $app->draw_objects( $map, @npcs, $player );
        }
    }
}

my $engine = Engine->new( width => 40, height => 25 )->run();
