use strict;
use warnings;
use Test::More tests=>9;
use Test::Fatal;

{
    package Test::MooseX::Meta::TypeConstraint::Structured::Combined;

    use Moose;
    use MooseX::Types::Structured qw(Dict Tuple);
    use MooseX::Types::Moose qw(Int Str Object ArrayRef HashRef Maybe);

    has 'dict_with_tuple' => (is=>'rw', isa=>Dict[key1=>Str, key2=>Tuple[Int,Str]]);
    has 'dict_with_tuple_with_union' => (is=>'rw', isa=>Dict[key1=>Str|Object, key2=>Tuple[Int,Str|Object]] );
}

## Instantiate a new test object

ok my $record = Test::MooseX::Meta::TypeConstraint::Structured::Combined->new
 => 'Instantiated new Record test class.';

isa_ok $record => 'Test::MooseX::Meta::TypeConstraint::Structured::Combined'
 => 'Created correct object type.';

## Test dict_with_tuple

is( exception {
    $record->dict_with_tuple({key1=>'Hello', key2=>[1,'World']});
} => undef, 'Set tuple attribute without error');

like( exception {
    $record->dict_with_tuple({key1=>'Hello', key2=>['World',2]});
}, qr/Attribute \(dict_with_tuple\) does not pass the type constraint/
 => 'Threw error on bad constraint');

## Test dict_with_tuple_with_union: Dict[key1=>'Str|Object', key2=>Tuple['Int','Str|Object']]

is( exception {
    $record->dict_with_tuple_with_union({key1=>'Hello', key2=>[1,'World']});
} => undef, 'Set tuple attribute without error');

like( exception {
    $record->dict_with_tuple_with_union({key1=>'Hello', key2=>['World',2]});
}, qr/Attribute \(dict_with_tuple_with_union\) does not pass the type constraint/
 => 'Threw error on bad constraint');

is( exception {
    $record->dict_with_tuple_with_union({key1=>$record, key2=>[1,'World']});
} => undef, 'Set tuple attribute without error');

is( exception {
    $record->dict_with_tuple_with_union({key1=>'Hello', key2=>[1,$record]});
} => undef, 'Set tuple attribute without error');

like( exception {
    $record->dict_with_tuple_with_union({key1=>1, key2=>['World',2]});
}, qr/Attribute \(dict_with_tuple_with_union\) does not pass the type constraint/
 => 'Threw error on bad constraint');
