use strict;
use warnings;
use Test::More;
use FFI::Platypus;

my %args;

no warnings 'redefine';
sub FFI::Platypus::attach {
  my($self, $name, $args, $ret) = @_;
  $args{$name->[0]} = $args;
  $self;
}

use parent qw( NativeCall );

sub foo1 :Args((int)->int) :Returns(void) {}
is_deeply $args{foo1}, [ '(int)->int' ];

sub foo2 :Args((int)->int,int) :Returns(void) {}
is_deeply $args{foo2}, [ '(int)->int', 'int' ];

sub foo3 :Args((int,int)->int) :Returns(void) {}
is_deeply $args{foo3}, [ '(int,int)->int' ];

sub foo4 :Args((int,int)->int,int,(string,int,int)->int) :Returns(void) {}
is_deeply $args{foo4}, [ '(int,int)->int', 'int', '(string,int,int)->int' ];

done_testing;
