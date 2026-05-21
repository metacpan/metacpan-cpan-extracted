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
    is My::App::one_ring->rule, 'them all';
} 'shortcut magic executed correctly';

throws_ok {
    package My::Err;
    Resource::Silo->import( -shortcut => "foo bar" );
} qr/shortcut.*identifier/, "bad name = no go";

throws_ok {
    package My::Err2;
    # meh...
    local $SIG{__WARN__} = sub { die $_[0] };
    Resource::Silo->import( -class );
    silo();
} qr/explicit.*shortcut/, "no more bare silo in class mode";

done_testing;
