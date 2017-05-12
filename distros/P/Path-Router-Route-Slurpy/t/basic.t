#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 20;

use Path::Router;
use Path::Router::Route::Slurpy;

my $router = Path::Router->new(
    route_class => 'Path::Router::Route::Slurpy',
    inline      => 0,
);


$router->add_route('/blah/blah');
$router->add_route('/zero/one/?:foo');
$router->add_route('/one/two/*:foo');
$router->add_route('/two/three/+:foo');

{
    my $match = $router->match('/blah/blah');
    ok($match);

    $match = $router->match("/zero/one");
    ok($match);
    is($match->mapping->{foo}, undef);

    $match = $router->match("/zero/one/two");
    ok($match);
    is($match->mapping->{foo}, 'two');

    $match = $router->match("/one/two");
    ok($match);
    is($match->mapping->{foo}, undef);

    $match = $router->match("/one/two/three");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'three' ]);

    $match = $router->match("/one/two/three/four");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'three', 'four' ]);

    $match = $router->match("/one/two/three/four/five");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'three', 'four', 'five' ]);

    $match = $router->match("/two/three");
    ok(!$match);

    $match = $router->match("/two/three/four");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'four' ]);

    $match = $router->match("/two/three/four/five");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'four', 'five' ]);

    $match = $router->match("/two/three/four/five/six");
    ok($match);
    is_deeply($match->mapping->{foo}, [ 'four', 'five', 'six' ]);
}
