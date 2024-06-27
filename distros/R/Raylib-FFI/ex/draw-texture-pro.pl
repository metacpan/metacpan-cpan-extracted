#!/usr/bin/env perl
use v5.38.2;
use lib qw(lib);

use Raylib::App;
use File::Share 'dist_file';

my $screenWidth  = 800;
my $screenHeight = 450;

my $app =
  Raylib::App->window( $screenWidth, $screenHeight,
    'texture source and destination rectangles' );

my $texture = Raylib::Texture->new(
    texture => dist_file( 'Raylib-FFI', 'assets/scarfy.png' ) );

my $frameWidth  = $texture->width / 6;
my $frameHeight = $texture->height;

my $sourceRec = Raylib::FFI::Rectangle->new(
    x      => 0,
    y      => 0,
    width  => $frameWidth,
    height => $frameHeight
);

my $destRec = Raylib::FFI::Rectangle->new(
    x      => $screenWidth / 2,
    y      => $screenHeight / 2,
    width  => $frameWidth * 2,
    height => $frameHeight * 2,
);

my $origin = Raylib::FFI::Vector2D->new( x => $frameWidth, y => $frameHeight );

my $rotation = 0;
while ( !$app->exiting ) {
    $rotation++;
    $app->draw(
        sub {
            $app->clear(Raylib::Color::RAYWHITE);
            if (0) {
                $texture->draw_rectangle(
                    $sourceRec,
                    $screenWidth / 2 - $frameWidth / 2,
                    $screenHeight / 2 - $frameHeight / 2
                );
            }
            $texture->draw_pro( $sourceRec, $destRec, $origin, $rotation,
                Raylib::Color::WHITE );

            $app->draw_line( $destRec->x, 0, $destRec->x, $screenHeight,
                Raylib::Color::GRAY );
            $app->draw_line( 0, $destRec->y, $screenWidth, $destRec->y,
                Raylib::Color::GRAY );
        }
    );
}
