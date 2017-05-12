use Test::More;
use Test::Exception;

use strict;
use warnings;

plan tests => 5;

{
  package TestX::Exports;

  use MooseX::Method qw/:compiled/;
  use Test::More;

  is_deeply (attr (foo => 1),{ foo => 1 });

  isa_ok (positional,'MooseX::Meta::Signature::Positional::Compiled');

  isa_ok (named,'MooseX::Meta::Signature::Named::Compiled');

  isa_ok (combined,'MooseX::Meta::Signature::Combined::Compiled');

  isa_ok (semi,'MooseX::Meta::Signature::Combined::Compiled');
}

