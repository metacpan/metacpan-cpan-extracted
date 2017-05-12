use strict;
use warnings;

use Test::More;
use MooseX::Types::NumUnit;
use Physics::Unit 'GetUnit';

is( GetUnit('mm')->convert('meter'), '0.001', 'mm is a millimeter' );

done_testing;

