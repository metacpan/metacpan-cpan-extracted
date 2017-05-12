use strict;
use warnings;

use Test::Deep;
use Test::More;

{
  package Foo;
  use Moose::Role;
  use t::Concatenator;

  add_result { wantarray ? (foo => [@_]) : [@_] };
}

{
  package Bar;
  use Moose::Role;
  use t::Concatenator;

  add_result { wantarray ? (bar => [@_]) : [@_] };
}

{
  package Thing;
  use Moose;
  use t::Concatenator;

  with qw(Foo Bar);

  sub _instance_result {
    return wantarray ? (instance => [@_]) : [@_];
  }

  add_result { wantarray ? (class => [@_]) : [@_] };
}

{
  package Baz;
  use Moose::Role;
  use t::Concatenator;

  add_result { wantarray ? (baz => [@_]) : [@_] };
}

{
  package Subthing;
  use Moose;
  extends 'Thing';
  with 'Baz';
  use t::Concatenator;

  add_result { wantarray ? (subclass => [@_]) : [@_] };
}

my $obj = Subthing->new;

my $scalar = $obj->results(qw(a b c));
my @list   = $obj->results(qw(a b c));

cmp_deeply(
  $scalar,
  bag(
    [ $obj, qw(a b c) ],
    [ $obj, qw(a b c) ],
    [ $obj, qw(a b c) ],
    [ $obj, qw(a b c) ],
    [ $obj, qw(a b c) ],
    [ $obj, qw(a b c) ],
  ),
  "scalar context results are as expected"
);

cmp_deeply(
  \@list,
  bag(
    [ foo => [ $obj, qw(a b c) ] ],
    [ bar => [ $obj, qw(a b c) ] ],
    [ baz => [ $obj, qw(a b c) ] ],
    [ instance => [ $obj, qw(a b c) ] ],
    [ class    => [ $obj, qw(a b c) ] ],
    [ subclass => [ $obj, qw(a b c) ] ],
  ),
  "list context results are as expected"
);

done_testing;
