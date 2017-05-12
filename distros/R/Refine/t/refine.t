use strict;
use Test::More;
use lib 't/disable-sub-name';
use Refine;

eval <<'TEST_CLASS' or die $@;
package Test::Class;
sub new { bless {}, shift }
sub dump { 42 }
$INC{'Test/Class.pm'} = 'generated';
TEST_CLASS

{
  my $t = Test::Class->new;
  is $t->dump, 42, 'original dump()';
  ok !$t->can('other_method'), 'other_method() is not defined';

  add_methods($t);
  is ref $t, 'Test::Class::WITH::dump::other_method::_0', 'Test::Class::WITH::dump::other_method::_0';
  isa_ok($t, 'Test::Class');
  is $t->other_method, 42, 'other_method() on t';
  is $t->dump, $t, 't->dump is redefined';

  my $t = Test::Class->new;
  add_methods($t);
  is ref $t, 'Test::Class::WITH::dump::other_method::_0', 'cached class';

  my $t = Test::Class->new;
  $t->$_refine(dump => sub { $_[0] }, other_method => sub { 42 });
  is ref $t, 'Test::Class::WITH::dump::other_method::_1', 'Test::Class::WITH::dump::other_method::_1';
}

{
  eval { Test::Class->$_refine(foo => sub { 123 }) };
  like $@, qr{Can only add}, 'Cannot refine classes';
}

SKIP: {
  skip 'Sub::Name might be available', 1 unless -r 't/disable-sub-name/Sub/Name.pm';
  my $t = Test::Class->new;
  $t->$_refine(throw => sub { Carp::confess('yikes!') });

  eval { $t->throw };
  like $@, qr{\bmain::__ANON__\(}, 'throw() has anon sub name';
}

done_testing;

sub add_methods {
  my $obj = shift;
  $obj->$_refine(dump => sub { $_[0] }, other_method => sub { 42 });
}
