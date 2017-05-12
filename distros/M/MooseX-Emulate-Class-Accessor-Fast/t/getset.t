#!perl
use strict;
use Test::More tests => 9;

require_ok("MooseX::Adopt::Class::Accessor::Fast");
{
  @Foo::ISA = qw(Class::Accessor::Fast);
  Foo->mk_accessors(qw( foo ));
  my $test = Foo->new({ foo => 49 });
  is( $test->get('foo'), 49, "get initial foo");
  $test->set('foo', 42);
  is($test->get('foo'), 42, "get new foo");
}

{
  @Bar::ISA = qw(Class::Accessor::Fast);
  my $get_ref = Bar->make_ro_accessor('read');
  my $set_ref = Bar->make_wo_accessor('write');
  my $getset_ref = Bar->make_accessor('read_write');

  ok(Bar->meta->has_attribute("read"),"has read");
  ok(Bar->meta->has_attribute("write"),"has write");
  ok(Bar->meta->has_attribute("read_write"),"has read_write");

  my $obj = Bar->new({read => 1, write => 2, read_write => 3});
  is($get_ref->($obj), 1, "read get works");
  is($getset_ref->($obj), 3, "read_write get works");
  $getset_ref->($obj,2);
  is($getset_ref->($obj), 2, "read_write set works");
}
