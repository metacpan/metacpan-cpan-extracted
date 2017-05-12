#!/opt/ecelerity/3rdParty/bin/perl -w 
use strict;
use Test::More tests => 3;

BEGIN {
    diag 'Check failed evals';
    use_ok 'PHP::Interpreter' or die;
}

ok my $p = new PHP::Interpreter(), "Create new PHP interpreter";
eval {
  $p->eval('ini_set("display_errors", "Off");');
  $p->eval('this isnt php');
};
like $@, qr/PHP Error in eval/, "eval error caught";
