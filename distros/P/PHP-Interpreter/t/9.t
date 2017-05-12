#!/opt/ecelerity/3rdParty/bin/perl -w 
use strict;
use Test::More tests => 8;

BEGIN {
    diag 'Instantiate a userland class with PHP::Interpreter::instantiate()';
    use_ok 'PHP::Interpreter' or die;
    use_ok 'PHP::Interpreter::Class' or die;
}

ok my $p = new PHP::Interpreter(), "Create new PHP interpreter";
$p->eval(q/
class Foo { 
  var $a = 789; 
  function __construct($a) { $this->a = $a; }
  function bar() { return 'george'; }
}; 
/);

my $arg = $p->instantiate('Foo', 123);

is ref($arg), "PHP::Interpreter::Class::Foo", "class membership correct";
is $arg->{a}, 123, "attribute access";
$arg->{a} = 456;
is $arg->{a}, 456, "attribute writing";
is $arg->bar(), 'george', 'function calls';
is $PHP::Interpreter::Class::Foo::ISA[0], 'PHP::Interpreter::Class', 'class inherits correctly';

