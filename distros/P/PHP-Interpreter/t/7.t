#!/opt/ecelerity/3rdParty/bin/perl -w 
use strict;
use Test::More tests => 8;

BEGIN {
    diag '3 ways of calling methods.';
    use_ok 'PHP::Interpreter' or die;
}
my $inc = 'test.inc';
# weird include path hack
chdir('t');
ok my $p = new PHP::Interpreter(), "Create new PHP interpreter";
ok my $a1 = $p->include($inc)->call('ident', 1), 
  "Including a PHP file and executing a function off iti via call";

ok my $p2 = new PHP::Interpreter(), "Create new PHP interpreter";
if($p2->is_multithreaded) {
  ok $a1 = $p2->include($inc)->ident(1), 
    "Including a PHP file and executing a function off iti via AUTOLOAD";
}
else {
  ok $a1 = $p2->include_once($inc)->ident(1), 
    "Including a PHP file and executing a function off iti via AUTOLOAD";
}

ok my $p3 = new PHP::Interpreter(), "Create new PHP interpreter";
if($p3->is_multithreaded) {
  ok $p3->include($inc), "Including a file";
} else {
  ok $p3->include_once($inc), "Including a file";
}
ok $p3->ident(1), 
  "... and executing a function off it via AUTOLOAD (2)";
