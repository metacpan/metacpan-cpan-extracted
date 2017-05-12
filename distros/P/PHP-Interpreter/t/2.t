#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 5;

BEGIN {
    diag "Testing basic function autoloadind";
    use_ok 'PHP::Interpreter' or die;
}

ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
ok $p->eval('function hello($a) { return "hello $a"; }'),
  'Add a "hello" function';
is $p->hello('george'),  'hello george',
  'We should get the proper return value of the "hello" function"';

is $p->eval('return "hello world";'), "hello world",
  "A simple eval should return the return value";
