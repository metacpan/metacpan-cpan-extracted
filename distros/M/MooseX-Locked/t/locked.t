use strict;
use warnings;
use Test::More tests => 6;

{
  package Foo;
  use Moose;
  use MooseX::Locked;
  has foo => ( is => 'rw' );
  has bar => ( is => 'bare' );
  sub bar { $_[0]->{bar} }
  sub baz { $_[0]->{baz} }
}
probe('mutable');

Foo->meta->make_immutable;
probe('immutable');

sub probe {
    my $c = shift;
    my $f = Foo->new( foo => 1, bar => 2 );
    ok(  eval { $f->foo }, "$c: foo");
    ok(  eval { $f->bar }, "$c: bar");
    ok( !eval { $f->baz } && $@ =~ /restricted hash/, "$c: baz error - restricted");
}
