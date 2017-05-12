#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Perl::Lint::Git' );
}

diag( "Testing Perl::Lint::Git $Perl::Lint::Git::VERSION, Perl $], $^X" );
