use 5.014;

use Do;
use Test::Auto;
use Test::More;

=name

Test::Auto::Parser

=abstract

Specification Parser

=synopsis

  package main;

  use Test::Auto;
  use Test::Auto::Parser;

  my $test = Test::Auto->new(
    't/Test_Auto_Parser.t'
  );

  my $parser = Test::Auto::Parser->new(
    source => $test
  );

=description

This package use the L<Test::Auto> object as a parser target, where the
object's file property points to a test file containing POD blocks which adhere
to the specification as defined in L<Test::Auto/SPECIFICATION>, parses the test
file and returns a parser object for accessing the data.

=libraries

Data::Object::Library

=attributes

name: ro, opt, ArrayRef[Str]
abstract: ro, opt, ArrayRef[Str]
synopsis: ro, opt, ArrayRef[Str]
includes: ro, opt, ArrayRef[Str]
description: ro, opt, ArrayRef[Str]
inherits: ro, opt, ArrayRef[Str]
integrates: ro, opt, ArrayRef[Str]
attributes: ro, opt, ArrayRef[Str]
libraries: ro, opt, ArrayRef[Str]
headers: ro, opt, ArrayRef[Str]
footers: ro, opt, ArrayRef[Str]
source: ro, req, InstanceOf["Test::Auto"]

=cut

package main;

my $test = Test::Auto->new(__FILE__);

$test->subtests->standard;

ok 1 and done_testing;
