use 5.014;

use lib 't/lib';

use strict;
use warnings;

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

This package parses files containing POD blocks which adhere to the
specification as defined in L<Test::Auto/SPECIFICATION>, and provides methods
for accessing the data.

=libraries

Test::Auto::Types

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
source: ro, req, Source

=cut

package main;

my $subs = testauto(__FILE__);

$subs = $subs->standard;

$subs->plugin('ShortDescription')->tests(length => 200);

ok 1 and done_testing;
