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
        param  => 'get',
        result => 'GET',
    },
    {
        param  => [qw/get POST/],
        result => 'GET, POST',
    },
    {
        param  => '*',
        result => ( join ', ', qw(GET DELETE POST PATCH OPTIONS HEAD CONNECT TRACE PUT) ),
    },
);

for my $test ( @tests ) {
    plugin SecurityHeader => [
        'Access-Control-Allow-Methods' => $test->{param},
    ];
    
    my $t = Test::Mojo->new;
    $t->get_ok('/')->status_is(200)->header_is('Access-Control-Allow-Methods', $test->{result} );
}

done_testing();
