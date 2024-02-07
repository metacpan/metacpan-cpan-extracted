#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    package My::App;

    use Resource::Silo -shortcut => 'one_ring';

    resource rule => sub { 'them all' };
    $INC{"My/App.pm"}++;
}

use My::App;

lives_and {
    is one_ring->rule, 'them all';
} 'shortcut magic executed correctly';

throws_ok {
    Resource::Silo->import( -shortcut => "foo bar" );
} qr/shortcut.*identifier/, "bad name = no go";

done_testing;
