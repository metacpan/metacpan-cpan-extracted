package main;

use 5.006;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Test;

parse   ( '"x"', parse => 'string' );
value   ( failures => [], 0 );
value   ( regular_expression => [], undef );
value   ( modifier => [], undef );

done_testing;

1;

# ex: set textwidth=72 :
