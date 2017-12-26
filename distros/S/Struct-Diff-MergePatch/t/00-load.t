#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Struct::Diff::MergePatch' ) || print "Bail out!\n";
}

diag( "Testing Struct::Diff::MergePatch $Struct::Diff::MergePatch::VERSION, Perl $], $^X" );
