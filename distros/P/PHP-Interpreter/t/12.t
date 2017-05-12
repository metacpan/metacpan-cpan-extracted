#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 6;

BEGIN {
    use_ok 'PHP::Interpreter' or die;
}

diag "Testing basic function autoloadind";
ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
ok $p->eval('function callme() { return Perl::getInstance(); }'),
  'Add a "callme" Perl::getInstance() wrapper';
ok $p->callme()->isa('PHP::Interpreter::Class::PerlObject'),
  'We should get a perl object back from Perl::getInstance()';
ok $p->eval(q!
  function callme2() { 
    $pl = Perl::getInstance(); 
    $rv = $pl->eval('return "hello";'); 
    return $rv;
  }
!),
  'Add a "callme2" wrapper';
is my $arg = $p->callme2(), "hello";
