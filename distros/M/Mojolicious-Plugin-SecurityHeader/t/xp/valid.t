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
        param  => 1,
        result => 1,
    },
    {
        param  => { value => 1, mode => 'block' },
        result => '1; mode=block',
    },
    {
        param  => { value => 1, report => 'https://perl-services.de' },
        result => '1; report=https://perl-services.de',
    },
);

for my $test ( @tests ) {
    plugin SecurityHeader => [
        'X-Xss-Protection' => $test->{param},
    ];
    
    my $t = Test::Mojo->new;
    $t->get_ok('/')->status_is(200)->header_is('X-Xss-Protection', $test->{result} );
}

done_testing();
