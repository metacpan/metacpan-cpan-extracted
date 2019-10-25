use strict;
use warnings;

use Open::This qw( parse_text );
use Test::More;
use Test::Warnings;

# Simulate an installed, non-local module
local $ENV{OPEN_THIS_LIBS} = '';
use lib 't/lib';

parse_text('Foo::Require');

done_testing();
