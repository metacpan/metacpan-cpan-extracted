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
        param  => '*',
        result => '*',
    },
    {
        param  => 'http://perl-services.de',
        result => "http://perl-services.de",
    },
);

for my $test ( @tests ) {
    plugin SecurityHeader => [
        'Access-Control-Allow-Origin' => $test->{param},
    ];
    
    my $t = Test::Mojo->new;
    $t->get_ok('/')->status_is(200)->header_is('Access-Control-Allow-Origin', $test->{result} );
}

done_testing();
