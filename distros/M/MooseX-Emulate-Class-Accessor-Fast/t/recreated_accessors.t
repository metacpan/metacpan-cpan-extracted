#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

# 1
use_ok('MooseX::Emulate::Class::Accessor::Fast');
{
  package My::Test::Package;
  use Moose;
  with 'MooseX::Emulate::Class::Accessor::Fast';
  for (0..1) {
    __PACKAGE__->mk_accessors(qw( foo ));
    __PACKAGE__->mk_ro_accessors(qw( bar ));
    __PACKAGE__->mk_wo_accessors(qw( baz ));
  }
}

my $i = My::Test::Package->new(bar => 'bar');

# 2
lives_ok {
  $i->foo('foo');
  $i->baz('baz');

  # 3-5
  is($i->foo, 'foo');
  is($i->bar, 'bar');
  is($i->{baz}, 'baz');
} 'No exception';

