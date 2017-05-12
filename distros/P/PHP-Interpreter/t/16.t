#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 9;

BEGIN {
    diag "Testing passing blessed references into PHP";
    use_ok 'PHP::Interpreter' or die;
}

our @var;
our $scalar;

push @var, "hello";
push @var, "goodbye";

ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
$p->eval(q/

function property_access($obj, $prop)
{
  return $obj->$prop;
}

function property_write($obj, $prop, $value)
{
  return $obj->$prop = $value;
}


function method_call($obj, $meth)
{
  return $obj->$meth();
}

function props_as_array($obj)
{
  $rv = array();
  foreach($obj as $k => $v) {
    $rv[$k] = $v;
  }
  return $rv;
}

/);
my $foo = new Foo();
$foo->{bar} = 'bar';
$foo->{baz} = 'baz';
is $p->get_class($foo), 'PerlSV::Foo', 'Checking class name';
is $p->property_access($foo, 'bar'), 'bar', 'Checking property access';
ok $p->property_write($foo, 'bar', 'foo'), 'Checking property write access';
is $p->property_access($foo, 'bar'), 'foo', 'Checking property access';
ok $p->property_write($foo, 'bar', 'bar'), 'Checking property write access';
is $p->method_call($foo, 'get'), 'bar', 'Checking method calls';
is_deeply $p->props_as_array($foo), {'bar' => 'bar', 'baz' => 'baz'}, 'Checking iterators';
package Foo;

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  bless {}, $class;
}

sub get {
  my ($self) = @_;
  return $self->{bar};
}

1;
