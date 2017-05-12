use strict;
use Test::More;
use Refine;

eval <<'TEST_CLASS' or die $@;
package Test::Class;
sub new { bless {}, shift }
sub dump { 42 }
$INC{'Test/Class.pm'} = 'generated';
TEST_CLASS

{
  my $t = Test::Class->new;

  add_methods($t);
  is ref $t, 'Test::Class::WITH::dump::other_method::_0', 'Test::Class::WITH::dump::other_method::_0';
  isa_ok($t, 'Test::Class');

  add_methods($t);
  add_methods($t);
  is ref $t, 'Test::Class::WITH::dump::other_method::_2', 'Test::Class::WITH::dump::other_method::_2';

  $t->$_refine(dump => sub { $_[0] }, other_method => sub { 42 }, foo => sub { 'foo' });
  is ref $t, 'Test::Class::WITH::dump::foo::other_method::_0', 'Test::Class::WITH::dump::foo::other_method::_0';
  is $t->dump, $t, 't->dump is redefined';
  is $t->foo, 'foo', 't->foo';
  is $t->other_method, 42, 't->other_method';
}

done_testing;

sub add_methods {
  my $obj = shift;
  $obj->$_refine(dump => sub { $_[0] }, other_method => sub { 42 });
}
