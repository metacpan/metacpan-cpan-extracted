use MooseX::Method::Constant;
use Test::More;

use strict;
use warnings;

plan tests => 3;

{
  my $constant = MooseX::Method::Constant->make (42);

  is (MooseX::Method::Constant::constant_1 (),42);

  is (eval "$constant",42);
}

{
  my $constant = MooseX::Method::Constant->make (sub { 42 });

  is (eval "$constant->()",42);
}

