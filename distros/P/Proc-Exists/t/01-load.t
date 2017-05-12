#!perl -w

use strict;
use Test::More tests => 1;

my $required_ok = 1;
eval {
	require Proc::Exists;
}; if($@) {
	diag( "can't load Proc::Exists: $@" );
	$required_ok = 0;
}
ok($required_ok);

#if we were able to load, output some extra info

if($required_ok) {
  no warnings 'once';
	my $impl = $Proc::Exists::pureperl ? "pureperl" :
		"XS (via ".$Proc::Exists::_loader.")";
	diag( "Testing Proc::Exists $Proc::Exists::VERSION, $impl implementation" );
}

