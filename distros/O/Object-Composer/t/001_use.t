
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok('Object::Composer') };

can_ok( 'Object::Composer', 'load' );

