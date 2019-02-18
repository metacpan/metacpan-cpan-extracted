#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

use MooX::Adopt::Class::Accessor::Fast;

{
  package TestAdoptCAF;

  use base 'Class::Accessor::Fast';

  __PACKAGE__->mk_accessors('foo');
  __PACKAGE__->mk_ro_accessors('bar');
  __PACKAGE__->mk_wo_accessors('baz');
}

ok(TestAdoptCAF->can('meta'), 'Adopt seems to work');

ok(!Class::Accessor::Fast->can('_get_moocaf_foo'),
  'methods not created on C::A::F');

SKIP: {
  my $moose_loaded = eval('require Moose; 1');
  skip( 'this test only works if Moose is installed', 3 )
    unless $moose_loaded;

  ok(TestAdoptCAF->meta->find_attribute_by_name($_), "attribute $_ created")
    for qw(foo bar baz);
}

{
  my $ok = eval {
    local $SIG{__WARN__} = sub { 
      die "Warning generated when new was called with no arguments: " . 
        join("; ", @_);
    };
    TestAdoptCAF->new(());
  };
  ok( ref($ok), ref($ok) ? "no warnings when instantiating object" : $@);
}

my $t = TestAdoptCAF->new(foo => 100, bar => 200, groditi => 300);
is($t->{foo},     100, '$self->{foo} set');
is($t->{bar},     200, '$self->{bar} set');
is($t->{groditi}, 300, '$self->{groditi} set');

my $u = TestAdoptCAF->new({foo => 100, bar => 200, groditi => 300});
is($u->{foo},     100, '$self->{foo} set');
is($u->{bar},     200, '$self->{bar} set');
is($u->{groditi}, 300, '$self->{groditi} set');

done_testing;
