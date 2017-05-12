#!/usr/bin/perl

# This test script validates assumptions that batch files work in the way
# they are expected to.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $^O eq 'MSWin32' ) {
		plan( tests => 3 );
	} else {
		plan( skip_all => 'Tests only runnable on Win32' );
		exit(0);
	}
}
use Portable::Dist        ();
use File::Spec::Functions ':ALL';





#####################################################################
# Test a simple echo

SCOPE: {
	my $file     = catfile( 't', 'data', 'bin', 'echo.bat' );
	my @stdout   = `$file`;
	my $curdir   = rel2abs(curdir());
	my @expected = (
		"\n",
	        "$curdir>echo Hello World! \n",
	        "Hello World!\n",
	);
        #workaroung for failure: 'C:\dirname\... ' vs. 'c:\dirname\...'
        @stdout = map { lc $_ } @stdout;
        @expected = map { lc $_ } @expected;
	is_deeply( \@stdout, \@expected, 'echo.bat ok' );
}





#####################################################################
# Test path interpolation for the called .bat file

SCOPE: {
	my $file     = catfile( 't', 'data', 'bin', 'interp.bat' );
	my @stdout   = `$file`;
	my $curdir   = rel2abs(curdir());
	my $bindir   = catdir($curdir, 't', 'data', 'bin');
	my $batfile  = catdir($curdir, $file);
	my @expected = (
		"\n",
	        "$curdir>echo $file \n",
	        "$file\n",
		"\n",
		"$curdir>echo $batfile \n",
		"$batfile\n",
		"\n",
		"$curdir>echo $bindir\\perl.exe \n",
		"$bindir\\perl.exe\n",
	);
        #workaroung for failure: 'C:\dirname\... ' vs. 'c:\dirname\...'
        @stdout = map { lc $_ } @stdout;
        @expected = map { lc $_ } @expected;
	is_deeply( \@stdout, \@expected, 'interp.bat ok' );
	my $perl = $expected[-1];
	chomp($perl);
	ok( -f $perl, 'Found perl.exe' );
}
	
1;
