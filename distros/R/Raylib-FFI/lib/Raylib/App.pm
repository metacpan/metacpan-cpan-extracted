use 5.38.0;
use experimental 'class';

use Raylib::Text;
use Raylib::Texture;

class Raylib::App {
    use Raylib::FFI;
    use Raylib::Color qw();

    field $title : param = $0;
    field $width : param;
    field $height : param;
    field $fps : param        = 60;
    field $background : param = Raylib::Color::BLACK;

    ADJUST {
        InitWindow( $width, $height, $title );
        if ( IsWindowReady() ) {
            SetTargetFPS($fps);
            ClearBackground($background);
        }
    }

    sub window ( $, $width, $height, $title = $0 ) {
        return __PACKAGE__->new(
            width  => $width,
            height => $height,
            title  => $title
        );
    }

    method toggle_fullscreen {
        ToggleFullscreen();
    }

    method toggle_borderless_windowed {
        ToggleBorderlessWindowed();
    }

    method fps ( $new_fps = undef ) {
        if ( defined $new_fps ) {
            $fps = $new_fps;
            SetTargetFPS($fps);

        }
        return $fps = GetFPS();
    }

    method clear ( $new_color = undef ) {
        if ( defined $new_color ) {
            $background = $new_color;
        }
        ClearBackground($background);
    }

    method exiting { WindowShouldClose() }

    method draw ($code) {
        BeginDrawing();
        $code->();
        EndDrawing();
    }

    method draw_line ( $x1, $y1, $x2, $y2, $color ) {
        DrawLine( $x1, $y1, $x2, $y2, $color );
    }

    method draws (@drawables) {
        $self->draw_objects(@drawables);
    }

    method draw_objects (@drawables) {
        BeginDrawing();
        $_->draw for @drawables;
        EndDrawing();
    }

    method draw3d ($code) {
        BeginDrawing();
        $code->();
        EndDrawing();
    }

    my sub timestamp {
        return strftime( '%Y-%m-%dT%H.%M.%S', gmtime(time) );
    }

    method screenshot ( $file = ( 'ScreenShot-' . timestamp() . '.png' ) ) {
        TakeScreenshot($file);
    }

    method height { $height = GetScreenHeight() }
    method width  { $width  = GetScreenWidth() }

    method key_pressed {
        return GetKeyPressed();
    }

    method DESTROY { CloseWindow() }
}

__END__

=pod

=encoding utf-8

=head1 NAME

Raylib::App - Perlish wrapper for Raylib videogame library

=head1 SYNOPSIS

    use 5.38.2;
    use lib qw(lib);
    use Raylib::App;

    my $app = Raylib::App->window( 800, 600, 'Testing!' );
    $app->fps(5);

    my $fps  = Raylib::Text::FPS->new();
    my $text = Raylib::Text->new(
        text  => 'Hello, world!',
        color => Raylib::Color::WHITE,
        size  => 20,
    );

    while ( !$app->exiting ) {
        my $x = $app->width() / 2;
        my $y = $app->height / 2;
        $app->draw(
            sub {
                $app->clear();
                $fps->draw();
                $text->draw( $x, $y );
            }
        );
    }

=head1 raylib

raylib is highly inspired by Borland BGI graphics lib and by XNA framework.
Allegro and SDL have also been analyzed for reference.

NOTE for ADVENTURERS: raylib is a programming library to learn videogames
programming; no fancy interface, no visual helpers, no auto-debugging... just
coding in the most pure spartan-programmers way. Are you ready to learn? Jump
to L<code examples|http://www.raylib.com/examples.html> or
L<games|http://www.raylib.com/games.html>!

=head1 DESCRIPTION

This module is a port of the L<Graphics::Raylib> module to use Raylib::FFI
instead of Graphics::Raylib::XS. It should be a drop-in replacement for
Graphics::Raylib, but it is a work in progress.

=head1 METHODS

=over 4

=item new((%args)

Create a new Raylib::App object. The following arguments are accepted:

=over 4

=item title (defaults to $0)

The tile of the application and the window. Defaults to the name of the script.

=item width

The width of the window.

=item height

The height of the window.

=item fps (defaults to 60)

The frames per second to target. Defaults to 60.

=item background (defaults to Raylib::Color::BLACK)

The background color of the window, defaults to Raylib::Color::Black.

=back

=item window($width, $height, [$title = $0])

An alternate constructor for creating a new Raylib::App object. This method
mirrors the API from Graphics::Raylib.

=item fps([$new_fps])

Get or set the frames per second for the application.

=item clear([$new_color])

Clear the window with the given color. If no color is given, the background
color for the app is used.

=item exiting()

Returns true if the window should close.

=item draw($code)

Begins drawing, calls C<< $code->() >> and ends drawing.

=item draws(@drawables)

Begins drawing, calls C<draw> on each object in the list, and ends drawing.

=item draw3d($code)

Begins drawing in 3D, calls C<< $code->() >> and ends drawing.

=item screenshot([$file])

Take a screenshot of the window and save it to the given file. If no file is
given, a default filename based on the current timestamp is used.

=item height() / width()

Get the height or width of the window.

=back

=head1 SEE ALSO

L<http://www.raylib.com>

L<Raylib::FFI>

L<Graphics::Raylib>

L<Alien::raylib>

=back

=head1 AUTHOR

Chris Prather <chris@prather.org>

Based on the work of:

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 RAYLIB LICENSE

This is an unofficial wrapper of L<http://www.raylib.com>.

raylib is Copyright (c) 2013-2016 Ramon Santamaria and available under the terms of the zlib/libpng license. Refer to C<XS/LICENSE.md> for full terms.

=cut
