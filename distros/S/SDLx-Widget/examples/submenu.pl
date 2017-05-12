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


my $show_menu = 1;
my $menu_event_id;
my $menu = SDLx::Widget::Menu->new( topleft => [100, 230] )->items(
    'Some Option'       => sub { },
    'Open Submenu'      => \&open_submenu,
    'Some Other Option' => sub { },
    'Quit'              => sub { $show_menu = 0; },
);

my $show_submenu = 0;
my $submenu = SDLx::Widget::Menu->new( topleft => [100, 530] )->items(
     'Item 1' => sub { },
     'Item 2' => sub { },
     'Item 3' => sub { },
     'Back'   => sub { $show_submenu = 0 },
);

open_menu();

$app->add_show_handler(
    sub {
        $app->draw_rect( undef, undef );
        $menu->render($app);
        $submenu->render($app) if $show_submenu;
        $app->update;
    }
);

$app->run;
exit;

sub open_submenu {
    $submenu->selected( undef );
    $show_submenu = 1;

    $app->remove_event_handler( $menu_event_id );

    my $submenu_id;
    $submenu_id = $app->add_event_handler( sub {
            $submenu->event_hook( $_[0] );

            if ($show_submenu == 0) {
                $app->remove_event_handler( $submenu_id );
                open_menu();
            }
    });
}

sub open_menu {
    $menu->selected( undef );

    $menu_event_id = $app->add_event_handler( sub {
        $menu->event_hook( $_[0] );
        $app->stop if $show_menu == 0;
    });
}

