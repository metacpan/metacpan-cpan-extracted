#!/opt/ecelerity/3rdParty/bin/perl -w 
use strict;
use Test::More tests => 5;

BEGIN {
#  use ExtUtils::testlib;
  diag "Testing passing and return nested arrays.";
  use_ok 'PHP::Interpreter' or die;
}

# weird include path hack
chdir('t');
ok my $p = new PHP::Interpreter(), "Creating a new PHP::Interpreter.";
ok $p->include('test.inc'), "including PHP testing functions.";
my @list = ('I', 'AM', 'AN', ['NESTED', 'ARRAY']);
ok my $arg = $p->ident(\@list), "Pass in a nested array and return it.";
is_deeply $arg, \@list, "Testing that return array equals passed array.";
