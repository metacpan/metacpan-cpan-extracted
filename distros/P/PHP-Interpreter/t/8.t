#!/opt/ecelerity/3rdParty/bin/perl -w 
use strict;
use Test::More tests => 8;
use Data::Dumper;

BEGIN {
    diag '3 ways of calling methods.';
    use_ok 'PHP::Interpreter' or die;
    use_ok 'PHP::Interpreter::Class' or die;
}

ok my $p = new PHP::Interpreter(), "Create new PHP interpreter";
$p->eval(q/
class Foo { 
  var $a = 123; 
  function bar() { return 'george'; }
}; 
function foo() { return $foo = new Foo();}

/);
my $arg = $p->foo();
is ref($arg), "PHP::Interpreter::Class::Foo", "class membership correct";
is $arg->{a}, 123, "attribute access";
$arg->{a} = 456;
is $arg->{a}, 456, "attribute writing";
is $arg->bar(), 'george', 'function calls';
is $PHP::Interpreter::Class::Foo::ISA[0], 'PHP::Interpreter::Class', 'class inherits correctly';
