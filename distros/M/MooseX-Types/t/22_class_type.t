use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

BEGIN {
  package MyTypes;

  use MooseX::Types::Moose qw( Item );
  use MooseX::Types -declare => [ 'ClassyType', 'NoClass' ];

  class_type 'ClassyClass';

  subtype ClassyType, as 'ClassyClass';

  subtype NoClass, as Item, where { 1 };
}

BEGIN {

  ok(!eval { MyTypes::ClassyType->new }, 'new without class loaded explodes');

  like($@, qr/does not provide/, 'right exception');

  ok(!eval { MyTypes::NoClass->new }, 'new on non-class type');

  like($@, qr/non-class-type/, 'right exception');
}

BEGIN {

  package ClassyClass;

  use Moose;

  sub check { die "FAIL" }

  package ClassyClassConsumer;

  BEGIN { MyTypes->import('ClassyType') }
  use Moose;

  has om_nom => (
    is => 'ro', isa => ClassyType, default => sub { ClassyType->new }
  );

}

ok(my $o = ClassyClassConsumer->new, "Constructor happy");

is(ref($o->om_nom), 'ClassyClass', 'Attribute happy');

ok(ClassyClassConsumer->new(om_nom => ClassyClass->new), 'Constructor happy');

ok(!eval { ClassyClassConsumer->new(om_nom => 3) }, 'Type checked');

done_testing;
