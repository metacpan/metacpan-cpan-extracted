use strict;
use warnings;

package MyTest;

use Test::More 'no_plan';
use Sub::Methodical;

sub foo :Methodical {
  return [ @_ ];
}

sub _extra { () }

sub bar {
  my $self = shift;
  #use Data::Dump::Streamer; Dump(\&foo)->To(\*STDERR)->Out;
  is_deeply(
    foo(1),
    [ $self->_extra, $self, 1 ],
    "methodical as function",
  );

  is_deeply(
    $self->foo(1),
    [ $self->_extra, $self, 1 ],
    "methodical as method",
  );
}

package MyTest::Derived;

BEGIN { our @ISA = qw(MyTest) }

package MyTest::OverrideFoo;

BEGIN { our @ISA = qw(MyTest) }
use Test::More;

# if any other functions that referenced foo() were also overridden, this would
# need to be explicitly :Methodical, but if they aren't, this works
sub foo {
  return [ 'OVERRIDE', @_ ];
}

sub _extra { 'OVERRIDE' }

package MyTest::OverrideBar;

BEGIN { our @ISA = 'MyTest' }
use Sub::Methodical -inherit;
use Test::More;

sub bar {
  my $self = shift;
  is_deeply(
    foo(1),
    [ $self->_extra, $self, 1 ],
    "methodical as function (AUTOLOAD)",
  );
  eval { baz(); };
  like $@, qr/Undefined subroutine &MyTest::OverrideBar::baz called/,
    'AUTOLOAD does not interfere with normal missing function mechanism';
}

package MyTest::OverrideAll;

BEGIN { our @ISA = 'MyTest' }
use Sub::Methodical -auto, -inherit;
use Test::More;

sub foo {
  return [ 'MOREOVER', @_ ];
}

sub _extra { 'MOREOVER' }

sub bar {
  my $self = shift;
  is_deeply(
    foo(1),
    [ $self->_extra, $self, 1 ],
    "methodical as function (AUTOLOAD)",
  );
}
no Test::More;

package main;

MyTest->bar;
MyTest::Derived->bar;
MyTest::OverrideFoo->bar;
MyTest::OverrideBar->bar;
MyTest::OverrideAll->bar;
