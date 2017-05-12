use strict;
use warnings;
use Test::More 0.88;

## Bug report was that if calling ->is_subtype on crap (not a type, etc) you
## get a not very helpful error message.  Fix was to make crap just return
## boolean false to make this like the rest of Moose type constraints.  I am
## not convinced this is good, but at least is consistent.
#
# I also changed ->equals and ->is_a_type_of to be consistent

{
    package moosex::types::structured::bug_is_subtype;

    use Moose;
    use MooseX::Types -declare => [qw/ ThingType  /];
    use MooseX::Types::Moose qw/ Int Str /;
    use MooseX::Types::Structured  qw/ Dict /;

    subtype ThingType, as Dict [ id  => Int, name => Str, ];
    has thing => ( is => 'ro', isa =>  ThingType, );
}

ok my $test = moosex::types::structured::bug_is_subtype->new,
  'created class';

is(
  moosex::types::structured::bug_is_subtype::ThingType,
  'moosex::types::structured::bug_is_subtype::ThingType',
  'correct type',
);

use MooseX::Types::Moose 'HashRef';

is(
  HashRef,
  'HashRef',
  'correct type',
);

ok(
  moosex::types::structured::bug_is_subtype::ThingType->is_subtype_of(HashRef),
  'is a subtype',
);

ok(
  !moosex::types::structured::bug_is_subtype::ThingType
    ->is_subtype_of(moosex::types::structured::bug_is_subtype::ThingType),
  'is not a subtype',
);

ok(
  !moosex::types::structured::bug_is_subtype::ThingType
    ->is_subtype_of('SomeCrap'),
  'is not a subtype',
);

sub SomeCrap {}

ok(
  !moosex::types::structured::bug_is_subtype::ThingType
    ->is_subtype_of(SomeCrap),
  'is not a subtype',
);

ok(
  !moosex::types::structured::bug_is_subtype::ThingType
    ->is_subtype_of(undef),
  'is not a subtype',
);

ok(
  !moosex::types::structured::bug_is_subtype::ThingType
    ->equals(undef),
  'is not a subtype',
);

ok(
  !moosex::types::structured::bug_is_subtype::ThingType
    ->is_a_type_of(undef),
  'is not a subtype',
);

done_testing;
