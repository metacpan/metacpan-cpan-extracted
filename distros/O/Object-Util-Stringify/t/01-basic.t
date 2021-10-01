#!perl

use strict;
use warnings;
use Test::More 0.98;

use Object::Util::Stringify qw(set_stringify unset_stringify);

my $obj1 = bless({}, "Foo");
my $obj2 = bless([], "Bar");

my $def_obj1_str = "$obj1";
my $def_obj2_str = "$obj2";

# before
is("$obj1", $def_obj1_str);
is("$obj2", $def_obj2_str);

set_stringify($obj1, "hello");
set_stringify($obj2, "world");

# after set_stringify
is("$obj1", "hello");
is("$obj2", "world");

set_stringify($obj1, "goodbye");

# after another set_stringify
is("$obj1", "goodbye");

unset_stringify($obj1);
unset_stringify($obj2);

# after unset_stringify
is("$obj1", $def_obj1_str);
is("$obj2", $def_obj2_str);

done_testing;
