use strict;
use warnings;
use SDLx::App;

use lib 'lib';
use SDLx::Widget::Menu;

my $app = SDLx::App->new(
    w   => 800,
    h   => 600,
    eoq => 1,
);

my $menu = SDLx::Widget::Menu->new( topleft => [200, 330] );
$menu->items(
    'New Game'  => sub { },
    'Load Game' => sub { },
    'Options'   => sub { },
    'Quit'      => sub { $menu->{exit} = 1; },
);

$app->add_event_handler(
    sub {
        $menu->event_hook( $_[0] );
        $app->stop if $menu->{exit};
    }
);

$app->add_show_handler(
    sub {
        $app->draw_rect( undef, undef );
        $menu->render($app);
        $app->update;
    }
);

$app->run;
