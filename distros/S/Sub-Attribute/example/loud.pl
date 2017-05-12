#!perl -w

use strict;

BEGIN{
	package Louder;
	use Sub::Attribute;
	use Data::Dumper ();

	sub Loud :ATTR_SUB{
		local $Data::Dumper::Deparse = 1;
		local $Data::Dumper::Indent  = 1;
		print Data::Dumper->Dump([\@_], ['*args']), "\n";
	}
}

use parent -norequire => qw(Louder);

sub bar :Loud(xyzzy){
	'bar';
}

sub decl_only :Loud;

eval q{
	sub in_eval :Loud;
};

my $x = sub :Loud { 'anon' };

print "OK.\n";
