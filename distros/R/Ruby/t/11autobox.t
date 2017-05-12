#!perl

use strict;
use warnings;

use Test::More;


BEGIN{
	if(eval "use autobox 2.5; 1"){
		plan tests => 19;
	}
	else{
		plan skip_all => 'autobox 2.5 not installed';
	}
}

BEGIN{ require_ok('Ruby') }

ok !eval{ []->class; 1 }, "scope-out";

{
	use Ruby -autobox;

	ok eval{ "foo"->class; 1 }, "string is autoboxed";
	ok eval{ 1->class; 1 },     "integer is autoboxed";
	ok eval{ 0xff->class;1},    "binary is autoboxed";
	ok eval{ 0.1->class; 1 },   "float is autoboxed";
	ok eval{ undef->class;1 },  "undef is autoboxed";
	ok eval{ []->class; 1 },    "array is autoboxed";
	ok eval{ {}->class; 1 },    "hash is autoboxed";
	ok eval{ sub{}->class; 1},  "code is autoboxed";
	#ok eval{ (\[])->class; 1},  "ref is autoboxed";

	is ""->class,    "Perl::Scalar", "\"\"->class is Perl::Scalar";
	is []->class,    "Perl::Array",  "[]->class is Perl::Array";
	is {}->class,    "Perl::Hash",   "{}->class is Perl::Hash";
	is sub{}->class, "Perl::Code",   "sub{}->class is Perl::Code";
	is((\0)->class,  "Perl::Ref",     "(\\0)->class is Perl::Ref");

	is((\@ARGV)->class, "Perl::Array", '(\@array)->method');

	use Ruby -no_autobox;

	ok !eval{ []->class; 1 }, "-no_autobox";

}
ok !eval{ []->class; 1 }, "scope-out";


use Ruby -autobox;

is_deeply( [qw(b c a)]->sort->to_perl, [qw(a b c)], 'method call');

