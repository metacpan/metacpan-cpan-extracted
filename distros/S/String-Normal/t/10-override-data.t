#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;

use String::Normal;
my $obj = String::Normal->new( 
    business_stem       => 't/data/stem.txt',
    business_stop       => 't/data/stop.txt',
    business_compress   => 't/data/compress.txt',
);

# stem
is $obj->transform( 'foo' ),                'fu',               "correct custom stem";
is $obj->transform( 'bar' ),                'br',               "correct custom stem";
is $obj->transform( 'baz' ),                'bz',               "correct custom stem";

# stop
is $obj->transform( 'one two three four' ), 'four two',         "correct custom stop";

# compress
is $obj->transform( 'foo bar baz qux' ),    'foobarbaz qux',    "correct custom stop";
is $obj->transform( 'bar foo baz qux' ),    'br bz fu qux',     "correct custom stop";
