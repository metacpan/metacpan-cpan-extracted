#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 18;

use Moose::Util::TypeConstraints;
use Path::Router;
use Path::Router::Route::Slurpy;

my $router = Path::Router->new(
    route_class => 'Path::Router::Route::Slurpy',
    inline      => 0,
);


$router->add_route('/blah/blah');
$router->add_route('/zero/one/?:foo',
    validations => {
        foo => qr/two/,
    },
);
$router->add_route('/one/two/*:foo',
    validations => {
        foo => subtype('ArrayRef[Str]', where { @$_ >= 2 && $_->[1] eq 'four' }),
    },
);
$router->add_route('/two/three/+:foo',
    validations => {
        foo => subtype('ArrayRef[Str]', where { @$_ == 3 && $_->[1] eq 'five' }),
    },
);

{
    my $match = $router->match('/blah/blah');
    ok($match);

    $match = $router->match("/zero/one");
    ok($match);
    is($match->mapping->{foo}, undef);

    $match = $router->match("/zero/one/two");
    ok($match);
    is($match->mapping->{foo}, 'two');

    $match = $router->match("/zero/one/three");
    ok(!$match);

    $match = $router->match("/one/two");
    ok($match);
    is($match->mapping->{foo}, undef);

    $match = $router->match("/one/two/three");
    ok(!$match);

    $match = $router->match("/one/two/three/four");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'three', 'four' ]);

    $match = $router->match("/one/two/three/four/five");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'three', 'four', 'five' ]);

    $match = $router->match("/two/three");
    ok(!$match);

    $match = $router->match("/two/three/four");
    ok(!$match);

    $match = $router->match("/two/three/four/five");
    ok(!$match);

    $match = $router->match("/two/three/four/five/six");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'four', 'five', 'six' ]);
}
