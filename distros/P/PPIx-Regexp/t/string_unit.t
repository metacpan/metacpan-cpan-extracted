package main;

use 5.006;

use strict;
use warnings;

use Test::More 0.88;

use lib qw{ inc };
use My::Module::Test;

my $warning;
local $SIG{__WARN__} = sub {
    $warning = $_[0];
    return;
};

parse   ( '"x"', parse => 'string' );
like     $warning, qr<\AThe 'parse' argument is deprecated>,
    'Make sure we got a deprecation warning';
value   ( failures => [], 0 );
value   ( regular_expression => [], undef );
value   ( modifier => [], undef );

done_testing;

1;

# ex: set textwidth=72 :
