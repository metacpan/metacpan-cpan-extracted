use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello Mojo!');
};
    
plugin SecurityHeader => [
    'X-Content-Type-Options' => 'nosniff',
];

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->header_is('X-Content-Type-Options', 'nosniff');

done_testing();
