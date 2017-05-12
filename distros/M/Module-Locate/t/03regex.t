use Test::More 'no_plan';

use strict;

use Module::Locate;

my %tests = map { chomp; @_ = split; reverse @_ } <DATA>;

while(my($test,$res) = each %tests) {
  if($res == $test =~ $Module::Locate::PkgRe) {
    ok(1, "$test - ". ($res ? join(', ' => $test =~ /$Module::Locate::PkgRe/) : "expected failure"));
  } else {
    ok(0, "$test - ABJECT FAILURE\n");
  }
}

__DATA__
1 foo
1 foo::bar
1 foo::bar::baz
1 a
1 a::b
1 a::bb::c
0 9pkg::b0rk
0 brok:en
0 valid::sym::table::
