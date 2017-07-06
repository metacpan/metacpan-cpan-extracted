#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

{

    package t;
    use Moo;
    use MooX::Options;

    1;
}

my $p = t->new_with_options;
ok( $p, 't has options' );

done_testing;
