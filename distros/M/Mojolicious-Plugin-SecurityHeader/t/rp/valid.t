use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello Mojo!');
};
    
for my $value ( qw(no-referrer no-referrer-when-downgrade same-origin origin strict-origin origin-when-cross-origin strict-origin-when-cross-origin unsafe-url) ) {
    plugin SecurityHeader => [
        'Referrer-Policy' => $value,
    ];
    
    my $t = Test::Mojo->new;
    $t->get_ok('/')->status_is(200)->header_is('Referrer-Policy', $value );
}

done_testing();
