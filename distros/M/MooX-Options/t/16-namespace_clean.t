#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;
use Test::More;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";

local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

BEGIN {
    use Module::Runtime qw(use_module);
    eval { use_module("TestNamespaceClean") }
        or plan skip_all => "This test needs namespace::clean";
}

ok( TestNamespaceClean->new, 'TestNamespaceClean is a package' );

{
    local @ARGV = ( '--foo', '12' );
    my $i = TestNamespaceClean->new_with_options;
    is $i->foo, 12, 'value save properly';
}

done_testing;

