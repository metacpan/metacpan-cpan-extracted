
use strict;
use warnings;

use Test::More tests => 1;

{

  package Example;
  use Moose;
  use MooseX::Attribute::ValidateWithException;

  has 'foo' => (
    isa      => 'Str',
    is       => 'rw',
    required => 1,
  );

  __PACKAGE__->meta->make_immutable;
  no Moose;
}

use Test::Fatal;

my $e = exception {
  my $instance = Example->new( foo => [], );
};

isa_ok( $e, 'MooseX::Attribute::ValidateWithException::Exception' );

note explain $e;

note "$e";
