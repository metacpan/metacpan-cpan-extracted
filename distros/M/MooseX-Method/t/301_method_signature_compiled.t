use MooseX::Meta::Method::Signature::Compiled;
use MooseX::Meta::Signature::Positional::Compiled;
use Test::More;

use strict;
use warnings;

plan tests => 2;

{
  my $signature = MooseX::Meta::Signature::Positional->new ({ isa => 'Int',required => 1 });

  my $method = MooseX::Meta::Method::Signature::Compiled->wrap_with_signature ($signature,sub { $_[1] }, 'Foo', 'bar');

  is ($method->body->(0,42),42);
}

{
  my $signature = MooseX::Meta::Signature::Positional::Compiled->new ({ isa => 'Int',required => 1 });

  my $method = MooseX::Meta::Method::Signature::Compiled->wrap_with_signature ($signature,sub { $_[1] }, 'Foo', 'bar');

  is ($method->body->(0,42),42);
}

