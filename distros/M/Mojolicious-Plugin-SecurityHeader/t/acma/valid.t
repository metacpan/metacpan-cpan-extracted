use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojolicious::Lite;

get '/' => sub {
    my $c = shift;
    $c->render(text => 'Hello Mojo!');
};

my @tests = (
    {
        param  => '1',
        result => '1',
    },
    {
        param  => '0',
        result => '0',
    },
);

for my $test ( @tests ) {
    plugin SecurityHeader => [
        'Access-Control-Max-Age' => $test->{param},
    ];
    
    my $t = Test::Mojo->new;
    $t->get_ok('/')->status_is(200)->header_is('Access-Control-Max-Age', $test->{result} );
}

done_testing();
