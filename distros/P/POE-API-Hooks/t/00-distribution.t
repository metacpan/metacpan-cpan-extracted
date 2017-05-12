use warnings;
use strict;
use Test::More;

eval "require Test::Distribution";
plan skip_all => 'Test::Distribution not found.' if $@;

import Test::Distribution not => [ qw|sig prereq description| ];


