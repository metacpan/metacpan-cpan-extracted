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
        param  => {
            script => '*',
        },
        result => 'script-src *; ',
    },
    {
        param  => {
            script => "* 'unsafe-inline'",
        },
        result => "script-src * 'unsafe-inline'; ",
    },
    {
        param  => {
            script => '*',
            object => '*',
        },
        result => 'script-src *; object-src *; ',
    },
    {
        param  => {
            script => '*',
            object => "* 'unsafe-inline'",
        },
        result => "script-src *; object-src * 'unsafe-inline'; ",
    },
    {
        param  => {
            script => '*',
            object => "* 'unsafe-inline'",
            img    => "* 'unsafe-inline'",
        },
        result => "script-src *; object-src * 'unsafe-inline'; img-src * 'unsafe-inline'; ",
    },
);

for my $test ( @tests ) {
    plugin SecurityHeader => [
        'Content-Security-Policy' => $test->{param},
    ];
    
    my $t = Test::Mojo->new;
    $t->get_ok('/')->status_is(200)->header_is('Content-Security-Policy', $test->{result} );
}

done_testing();
