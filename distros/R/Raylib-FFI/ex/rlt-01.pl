use 5.38.2;
use lib qw(lib);
use experimental 'class';

use Raylib::App;

class Engine {
    use Raylib::Keyboard;

    my $WIDTH  = 800;
    my $HEIGHT = 500;

    field $player_x = $WIDTH / 2;
    field $player_y = $HEIGHT / 2;

    field $app = Raylib::App->window( $WIDTH, $HEIGHT, 'Map' );

    ADJUST {
        $app->fps(60);
    }

    field $player = Raylib::Text->new(
        text  => '@',
        color => Raylib::Color::WHITE,
        size  => 10,
    );

    field $keyboard = Raylib::Keyboard->new(
        key_map => {

            # vim keys
            KEY_H() => sub { $player_x -= 10 },
            KEY_L() => sub { $player_x += 10 },
            KEY_K() => sub { $player_y -= 10 },
            KEY_J() => sub { $player_y += 10 },

            # wasd keys
            KEY_W() => sub { $player_y -= 10 },
            KEY_S() => sub { $player_y += 10 },
            KEY_A() => sub { $player_x -= 10 },
            KEY_D() => sub { $player_x += 10 },

            # arrow keys
            KEY_UP()    => sub { $player_y -= 10 },
            KEY_DOWN()  => sub { $player_y += 10 },
            KEY_LEFT()  => sub { $player_x -= 10 },
            KEY_RIGHT() => sub { $player_x += 10 },
        },
    );

    method run() {
        while ( !$app->exiting ) {
            $keyboard->handle_events();
            $app->clear();
            $app->draw( sub { $player->draw( $player_x, $player_y ); } );
        }
    }
}

Engine->new->run;
