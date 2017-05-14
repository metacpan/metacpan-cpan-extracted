package MyApp::Bar;

use 5.012;
use warnings;

use Dancer2;
use Plack::Session;

get '/' => sub {
    my $session = Plack::Session->new( shift->env );

    'Hi! do you wanna dance? ' . $session->get('email');
};

1;
