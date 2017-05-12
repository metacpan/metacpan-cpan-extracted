use strictures 1;
use Test::More;
use Test::CleanNamespaces;

BEGIN {
  package Foo;
  use Moo;
  use MooX::Aliases;
  has bar => ( is => 'ro', alias => 'baz', );
  use namespace::clean;
}

namespaces_clean('Foo');

done_testing;
