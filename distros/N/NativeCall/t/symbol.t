use strict;
use warnings;
use Test::More;
use FFI::Platypus;

my %sym;

no warnings 'redefine';
sub FFI::Platypus::attach {
  my($self, $name, $args, $ret) = @_;
  $sym{$name->[1]} = $name->[0];
  $self;
}

use parent qw( NativeCall );

sub foo1 :Returns(void) :Symbol(bar1) {}
is $sym{'main::foo1'}, 'bar1';

sub foo2 :Returns(void) {}
is $sym{'main::foo2'}, 'foo2';

done_testing;
