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

