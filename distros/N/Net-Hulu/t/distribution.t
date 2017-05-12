#perform various distribution tests

use strict;
use warnings;
use Test::More;

eval 'require Test::Distribution';

plan( skip_all => 'TestDistribution not installed' ) if $@;

Test::Distribution->import( only => [ qw( versions description use pod sig ) ] );
