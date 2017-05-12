#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 3;

BEGIN {
    use_ok 'PHP::Interpreter' or die;
}

diag "Testing basic function autoloadind";
ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
$p->eval('function callme() { foo(); }');
eval {
  $p->callme();
};
like $@, qr/A PHP error occurred/, "Fatal PHP errors can be caught";
