use strict;
use warnings;

use Test::Most;
use MooseX::Params::TypeConstraints;
use Moose::Util::TypeConstraints;

my $array = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Array');
isa_ok $array, 'MooseX::Params::Meta::TypeConstraint::Listable';
ok $array->listable, 'array type constraint is listable';
ok $array->check([]), 'array type constraint matches arrayref';
ok !$array->check({}), 'array type constraint does not match hashref';

my $array_of_str = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Array[Str]');
isa_ok $array_of_str, 'Moose::Meta::TypeConstraint::Parameterized';
ok $array_of_str->parent->listable,
    'array of strings parent type constraint is listable';
ok $array_of_str->check([qw(foo bar)]),
    'array of strings type constraint matches arrayref of strings';
ok !$array_of_str->check([[],[]]),
    'array of strings type constraint does not match arrayref of arrayrefs';

my $hash = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Hash');
isa_ok $hash, 'MooseX::Params::Meta::TypeConstraint::Listable';
ok $hash->listable, 'hash type constraint is listable';
ok $hash->check({}), 'hash type constraint matches hashref';
ok !$hash->check([]), 'hash type constraint does not match arrayref';

my $hash_of_str = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Hash[Str]');
isa_ok $hash_of_str, 'Moose::Meta::TypeConstraint::Parameterized';
ok $hash_of_str->parent->listable,
    'hash of strings type constraint is listable';
ok $hash_of_str->check({foo => 'bar', baz => 'quz'}),
    'hash of strings type constraint matches hashref of strings';
ok !$hash_of_str->check({foo => {}, bar => {}}),
    'hash of strings type constraint does not match hashref of hashrefs';

done_testing;
