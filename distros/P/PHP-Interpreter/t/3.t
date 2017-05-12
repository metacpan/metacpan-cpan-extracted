#!/opt/ecelerity/3rdParty/bin/perl -w 
use strict;
use ExtUtils::testlib;
use Test::More tests => 5;

BEGIN {
    use_ok 'PHP::Interpreter' or die;
}

diag "Testing passing Perl AVs to PHP functions.";
# weird include path hack
chdir('t');
ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
ok $p->include('test.inc'), 'include PHP testing suite';
my @list = ('I', 'AM', 'AN', 'ARRAY');
ok my $newlist = $p->ident(\@list), 'Pass an AV into PHP, return an AV.';
is_deeply $newlist, \@list, "Checking arrays are identical.";
