#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
    use Cwd;
    chdir '..' if getcwd =~ m@/t$@;
    use lib 'lib';
    use lib 't/lib';
}

package basic;

use Test::Most;
use Test::Fatal;

run();

done_testing;

exit;

sub run {
    like( exception { test(); }, qr(Undefined subroutine &basic::test called), "function does not exist yet" );
    use_ok( 'Test', 'test' );
    is( test(), 'test', 'function is imported properly' );

    like( exception { test2(); }, qr(Undefined subroutine &basic::test2 called), "second function does not exist yet" );
    use_ok( 'Test', 'test', 'test2' );
    is( test2(), 'test2', 'multiple functions are imported properly' );

    return;
}
