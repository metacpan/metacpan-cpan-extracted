#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 1.001013;
use Test::Fatal 0.012;

use Path::Router;

{
    my $router = Path::Router->new;

    $router->add_route('/foo' =>
        defaults => { a => 'b', c => 'd', e => 'f' }
    );
    $router->add_route('/bar' =>
        defaults => { a => 'b', c => 'd' }
    );

    is($router->uri_for(a => 'b'), 'bar');
}

{
    my $router = Path::Router->new;

    $router->add_route('/bar' =>
        defaults => { a => 'b', c => 'd' }
    );
    $router->add_route('/foo' =>
        defaults => { a => 'b', c => 'd', e => 'f' }
    );

    is($router->uri_for(a => 'b'), 'bar');
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo' =>
        defaults => { a => 'b', c => 'd', e => 'f' }
    );
    $router->add_route('/bar' =>
        defaults => { a => 'b', c => 'd', g => 'h' }
    );

    like(
        exception { $router->uri_for(a => 'b', c => 'd') },
        qr{^\QAmbiguous path descriptor (specified keys a, c): could match paths /bar, /foo},
        "error when it's actually ambiguous"
    );
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo/:bar' => (defaults => { id => 1 }));
    $router->add_route('/foo/bar'  => (defaults => { id => 2 }));

    my $match = $router->match('/foo/bar');
    is($match->mapping->{id}, 2);
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo/bar'  => (defaults => { id => 2 }));
    $router->add_route('/foo/:bar' => (defaults => { id => 1 }));

    my $match = $router->match('/foo/bar');
    is($match->mapping->{id}, 2);
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo/:bar' => (defaults => { id => 1 }));
    $router->add_route('/:foo/bar' => (defaults => { id => 2 }));

    like(
        exception { $router->match('/foo/bar') },
        qr{^\QAmbiguous match: path foo/bar could match any of /:foo/bar, /foo/:bar},
        "error when it's actually ambiguous"
    );
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo/bar/?:baz' => (defaults => { id => 1 }));
    $router->add_route('/foo/:bar'      => (defaults => { id => 2 }));

    my $match = $router->match('/foo/bar');
    is($match->mapping->{id}, 1, "optional components don't matter");
}

{
    my $router = Path::Router->new;

    $router->add_route('/foo/:bar'      => (defaults => { id => 2 }));
    $router->add_route('/foo/bar/?:baz' => (defaults => { id => 1 }));

    my $match = $router->match('/foo/bar');
    is($match->mapping->{id}, 1, "optional components don't matter");
}

done_testing;
