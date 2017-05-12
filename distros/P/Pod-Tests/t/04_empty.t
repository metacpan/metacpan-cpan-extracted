#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;

# Changes is just a convenient file with no tests in it.
my $out = `$^X "-Ilib" script/pod2test Changes`;
is( $?/256, 1,     'pod2test exited with 1' );
is( $out, '',      '  and outputed nothing' );

ok( !-e 't/foofer', 'dummy pod2test output file doesnt exist' );
$out = `$^X "-Ilib" script/pod2test Changes t/foofer`;
is( $?/256, 1,      'pod2test exited with 1' );
is( $out, '',       '  and outputed nothing' );
ok( !-e 't/foofer', '  and didnt generate a file' );

