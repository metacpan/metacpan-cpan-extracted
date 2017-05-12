#!/opt/ecelerity/3rdParty/bin/perl -w 
use strict;
use Test::More tests => 5;
use Data::Dumper;

BEGIN {
    diag 'Instantiate an internal class with PHP::Interpreter::instantiate()';
    use_ok 'PHP::Interpreter' or die;
    use_ok 'PHP::Interpreter::Class' or die;
}

ok my $p = new PHP::Interpreter(), "Create new PHP interpreter";

my $arg = $p->instantiate('stdClass');

is ref($arg), "PHP::Interpreter::Class::stdClass", "class membership correct";
is $PHP::Interpreter::Class::stdClass::ISA[0], 'PHP::Interpreter::Class', 'class inherits correctly';
