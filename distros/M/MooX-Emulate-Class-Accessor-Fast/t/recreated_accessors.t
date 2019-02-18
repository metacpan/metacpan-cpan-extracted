#!/usr/bin/env perl
use strictures 2;
use Test2::V0;

use MooX::Emulate::Class::Accessor::Fast;

{
  package My::Test::Package;
  use Moo;
  with 'MooX::Emulate::Class::Accessor::Fast';
  for (0..1) {
    __PACKAGE__->mk_accessors(qw( foo ));
    __PACKAGE__->mk_ro_accessors(qw( bar ));
    __PACKAGE__->mk_wo_accessors(qw( baz ));
  }
}

my $i = My::Test::Package->new(bar => 'bar');

$i->foo('foo');
$i->baz('baz');

is($i->foo, 'foo');
is($i->bar, 'bar');
is($i->{baz}, 'baz');

done_testing;
