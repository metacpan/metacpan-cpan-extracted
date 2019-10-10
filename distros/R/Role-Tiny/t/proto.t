use strict;
use warnings;
use Test::More;

my $invalid_prototypes;

BEGIN {
  package TestExporter1;
  $INC{"TestExporter1.pm"} = 1;
  use Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(guff welp farb tube truck);

  sub guff     { rand(1) }
  sub welp ()  { rand(1) }
  sub farb ($) { rand(1) }

  no warnings;

  eval q{
    sub tube (plaf) { rand(1) }
    sub truck (-1) { rand(1) }
    1;
  } and $invalid_prototypes = 1;
}

BEGIN {
  package TestRole1;
  use Role::Tiny;
  use TestExporter1;
}

BEGIN {
  package SomeClass;
  use Role::Tiny::With;
  use TestExporter1;
  with 'TestRole1';
  eval { guff };
  ::is $@, '',
    'composing matching function with no prototype works';
  eval { welp };
  ::is $@, '',
    'composing matching function with empty prototype works';
  eval { farb 1 };
  ::is $@, '',
    'composing matching function with ($) prototype works';

  if ($invalid_prototypes) {
    eval { &tube };
    ::is $@, '',
      'composing matching function with invalid prototype works';
    eval { &truck };
    ::is $@, '',
      'composing matching function with invalid -1 prototype works';
  }
}

done_testing;
