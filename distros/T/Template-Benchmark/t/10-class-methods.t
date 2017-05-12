#!perl -T

use strict;
use warnings;

use Test::More;

use Template::Benchmark;

plan tests => 4;

#  These are deeply naff tests, but any errors in calling them
#  will be provoked, at the least.

#
#  1: default_options()
{
    my %h = Template::Benchmark->default_options();
    is( scalar( keys( %h ) ), 40, 'default_options()' );
}

#
#  2: valid_cache_types()
is( scalar( Template::Benchmark->valid_cache_types() ), 6,
    'valid_cache_types()' );

#
#  3: valid_features()
is( scalar( Template::Benchmark->valid_features() ), 24,
    'valid_features()' );

#
#  4: _engine_leaf().
#  Not actually a method, it's a sub.
is( Template::Benchmark::_engine_leaf(
        'Template::Benchmark::Engines::TemplateSandbox' ),
    'TemplateSandbox',
    '_engine_leaf()' );
