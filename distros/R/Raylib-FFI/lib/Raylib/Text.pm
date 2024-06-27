use 5.38.2;
use experimental 'class';

class Raylib::Text {
    use Raylib::FFI;

    field $text : param;
    field $color : param;
    field $position : param = [ 0, 0 ];
    field $size : param     = 10;

    method draw (@position) {
        @position = @$position unless @position;
        DrawText( $text, @position, $size, $color );
    }

    method text() { $text }
}

class Raylib::Text::FPS {
    use Raylib::FFI;
    field $position : param = [ 0, 0 ];

    method draw() {
        DrawFPS(@$position);
    }
}

