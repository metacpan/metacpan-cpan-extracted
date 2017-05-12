#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 1.001013;

use Path::Router;

my $router = Path::Router->new;
{
    my $warning;
    local $SIG{__WARN__} = sub { $warning .= $_[0] };
    $router->add_route(
        '/foo/:bar' => (
            validations => {
                baz => 'Int',
            },
        ),
    );

    like(
        $warning,
        qr+Validation provided for component :baz, but the path /foo/:bar doesn't contain a variable component with that name+,
        "got a warning"
    );
}

done_testing;
