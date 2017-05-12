#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 3;

BEGIN {
    use_ok 'PHP::Interpreter' or die;
}

diag "Testing basic function autoloadind";
ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
is $p->sandwich_test(), "mmmm... peanut butter",
  'We should get the proper return value of the "callme" function';
