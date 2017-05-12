use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Type::Tiny;

BEGIN {
  package MooClassMXTT;
  use Moo;
  use MooX::TypeTiny;
  use Types::Standard qw(Int);

  has attr1 => (
    is => 'ro',
    isa => Int,
  );
}

BEGIN {
  package MooClassStandard;
  use Moo;
  use Types::Standard qw(Int);

  has attr1 => (
    is => 'ro',
    isa => Int,
  );
}

BEGIN {
  package MooClassOuter;
  use Moo;
  use Types::Standard qw(Int);

  has attrMXTT => (
    is => 'rw',
    isa => sub { MooClassMXTT->new(attr1 => $_[0]) },
  );
  has attrStandard => (
    is => 'rw',
    isa => sub { MooClassStandard->new(attr1 => $_[0]) },
  );
}

my $o = MooClassOuter->new;

like exception {
  $o->attrStandard(1.5);
}, qr/attr1/,
  'exception should be for inner attribute (Standard)';

like exception {
  $o->attrMXTT(1.5);
}, qr/attr1/,
  'exception should be for inner attribute (MooX::TypeTiny)';

done_testing;
