#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 7;

BEGIN {
    use_ok 'PHP::Interpreter' or die;
}

our @var;
our $scalar;

push @var, "hello";
push @var, "goodbye";

diag "Testing basic function autoloadind";
ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
ok $p->eval(q/
    function foo() {
        $perl = Perl::getInstance();
        $value = $perl->getVariable('@main::var');
        return $value;
    }
    function bar() {
        $perl = Perl::getInstance();
        $value = $perl->getVariable('$main::var[0]');
        return $value;
    }
/), 'Define PHP function that returns Perl values';
my $phpval = $p->foo();
ok $phpval->[0] eq 'hello', 'Check return value of PHP foo()';
$phpval = $p->bar();
ok $phpval eq 'hello', 'Check return value of PHP bar()';
ok $p->eval(q/
  $a = new StdClass();
  $a->name = 'george';
  $perl = Perl::getInstance();
  $perl->setVariable('$scalar', $a);
/), 'Test use of Perl::setVariable';


is $scalar->{name}, 'george', 'Test scalar version of setVariable';
