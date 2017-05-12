#!perl -w

use strict;
use Test::More tests => 1;
use lib "./blib/lib";

my $required_ok = 1;
eval {
	require Number::Range::Regex;
}; if($@) {
	diag( "can't load Number::Range::Regex: $@" );
	$required_ok = 0;
}
ok($required_ok);

#if we were able to load, output some extra info

if($required_ok) {
	diag( "Testing Number::Range::Regex $Number::Range::Regex::VERSION" );
	#the rest of this is just to shut up the warnings pragma
}

