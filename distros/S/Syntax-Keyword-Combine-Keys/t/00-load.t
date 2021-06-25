#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
	use Syntax::Keyword::Combine::Keys;
	ok(1);
}

diag( "Testing Syntax::Keyword::Combine::Keys $Syntax::Keyword::Combine::Keys::VERSION, Perl $], $^X" );
