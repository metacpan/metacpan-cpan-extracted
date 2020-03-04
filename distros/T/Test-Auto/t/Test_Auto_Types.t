use 5.014;

use lib 't/lib';

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Test::Auto::Types

=abstract

Test-Auto Type Constraints

=synopsis

  package main;

  use Test::Auto::Types;

  1;

=description

This package provides type constraints for L<Test::Auto>.

=inherits

Types::Standard

=type Parser

  Parser

=type-parent Parser

  Object

=type-library Parser

Test::Auto::Types

=type-composite Parser

  InstanceOf['Test::Auto::Parser']

=type-example-1 Parser

  require Test::Auto;
  require Test::Auto::Parser;

  my $test = Test::Auto->new('t/Test_Auto.t');
  my $parser = Test::Auto::Parser->new(source => $test);

=type Source

  Source

=type-parent Source

  Object

=type-library Source

Test::Auto::Types

=type-composite Source

  InstanceOf['Test::Auto']

=type-example-1 Source

  require Test::Auto;

  my $test = Test::Auto->new('t/Test_Auto.t');

=type Strings

  Strings

=type-library Strings

Test::Auto::Types

=type-composite Strings

  ArrayRef[Str]

=type-example-1 Strings

  ['abc', 123]

=type Subtests

  Subtests

=type-parent Subtests

  Object

=type-library Subtests

Test::Auto::Types

=type-composite Subtests

  InstanceOf['Test::Auto::Subtests']

=type-example-1 Subtests

  require Test::Auto;
  require Test::Auto::Parser;
  require Test::Auto::Subtests;

  my $test = Test::Auto->new('t/Test_Auto.t');
  my $parser = Test::Auto::Parser->new(source => $test);
  my $subs = Test::Auto::Subtests->new(parser => $parser);

=cut

package main;

my $test = Test::Auto->new(__FILE__);

my $subs = $test->subtests->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result, 'result ok';

  $result;
});

ok 1 and done_testing;
