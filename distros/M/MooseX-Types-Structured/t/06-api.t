use strict;
use warnings;
use Test::More tests=>88;

{
    package TypeLib;
    use MooseX::Types::Structured qw(Dict Tuple);
    use MooseX::Types::Moose qw(Int Str Item Object ArrayRef HashRef);
    use MooseX::Types -declare => [qw(
        MyDict1 MyDict2 MyDict3 MyDict4 subMyDict3 subMyDict1
        MyTuple1 MyTuple2 MyTuple3 subMyTuple3
    )];

    ## Create some sample Dicts

    subtype MyDict1,
    as Dict[name=>Str, age=>Int];

    subtype subMyDict1,
    as MyDict1;

    subtype MyDict2,
    as Dict[name=>Str, age=>Int];

    subtype MyDict3,
    as Dict[key=>Int, anotherkey=>Str];

    subtype subMyDict3,
    as MyDict3;

    subtype MyDict4,
    as Dict[name=>Str, age=>Item];

    ## Create some sample Tuples

    subtype MyTuple1,
    as Tuple[Int,Int,Str];

    subtype MyTuple2,
    as Tuple[Int,Int,Str];

    subtype MyTuple3,
    as Tuple[Object, HashRef];

    subtype subMyTuple3,
    as MyTuple3;
}

use Moose::Util::TypeConstraints;
use MooseX::Types::Structured qw(Dict Tuple);
use MooseX::Types::Moose qw(Int Str Item Object ArrayRef HashRef);

BEGIN {
    TypeLib->import(':all');
}

## Test equals

ok ( MyDict1->equals(MyDict2), 'MyDict1 == MyDict2');
ok ( MyDict2->equals(MyDict1), 'MyDict2 == MyDict1');
ok (!MyDict1->equals(MyDict3), 'MyDict1 == MyDict3');
ok (!MyDict2->equals(MyDict3), 'MyDict2 == MyDict3');
ok (!MyDict3->equals(MyDict2), 'MyDict3 == MyDict2');
ok (!MyDict3->equals(MyDict1), 'MyDict3 == MyDict1');

ok ( MyTuple1->equals(MyTuple2), 'MyTuple1 == MyTuple2');
ok ( MyTuple2->equals(MyTuple1), 'MyTuple2 == MyTuple1');
ok (!MyTuple1->equals(MyTuple3), 'MyTuple1 == MyTuple3');
ok (!MyTuple2->equals(MyTuple3), 'MyTuple2 == MyTuple3');
ok (!MyTuple3->equals(MyTuple2), 'MyTuple3 == MyTuple2');
ok (!MyTuple3->equals(MyTuple1), 'MyTuple3 == MyTuple1');

ok ( MyDict1->equals(MyDict2), 'MyDict1 == MyDict2');
ok ( MyDict2->equals(MyDict1), 'MyDict2 == MyDict1');
ok (!MyDict1->equals(MyDict3), 'MyDict1 == MyDict3');
ok (!MyDict1->equals(MyDict4), 'MyDict1 == MyDict3');
ok (!MyDict2->equals(MyDict3), 'MyDict2 == MyDict3');
ok (!MyDict2->equals(MyDict4), 'MyDict2 == MyDict3');
ok (!MyDict3->equals(MyDict2), 'MyDict3 == MyDict2');
ok (!MyDict3->equals(MyDict4), 'MyDict3 == MyDict2');
ok (!MyDict3->equals(MyDict1), 'MyDict3 == MyDict1');
ok (!MyDict4->equals(MyDict1), 'MyDict3 == MyDict1');
ok (!MyDict4->equals(MyDict2), 'MyDict3 == MyDict1');
ok (!MyDict4->equals(MyDict3), 'MyDict3 == MyDict1');

ok ( MyTuple1->equals(MyTuple2), 'MyTuple1 == MyTuple2');
ok ( MyTuple2->equals(MyTuple1), 'MyTuple2 == MyTuple1');
ok (!MyTuple1->equals(MyTuple3), 'MyTuple1 == MyTuple3');
ok (!MyTuple2->equals(MyTuple3), 'MyTuple2 == MyTuple3');
ok (!MyTuple3->equals(MyTuple2), 'MyTuple3 == MyTuple2');
ok (!MyTuple3->equals(MyTuple1), 'MyTuple3 == MyTuple1');

## Test is_a_type_of

ok ( MyDict1->is_a_type_of(HashRef), 'MyDict1 is_a_type_of HashRef');
ok ( MyDict1->is_a_type_of(Dict), 'MyDict1 is_a_type_of Dict');
ok (!MyDict1->is_a_type_of(Tuple), 'MyDict1 NOT is_a_type_of Tuple');
ok ( MyDict1->is_a_type_of(MyDict2), 'MyDict1 is_a_type_of MyDict2');
ok ( MyDict2->is_a_type_of(MyDict1), 'MyDict2 is_a_type_of MyDict1');
ok (!MyDict1->is_a_type_of(MyDict3), 'MyDict1 NOT is_a_type_of MyDict3');
ok (!MyDict2->is_a_type_of(MyDict3), 'MyDict2 NOT is_a_type_of MyDict3');
ok ( subMyDict1->is_a_type_of(Dict), 'subMyDict1 type of Dict');
ok ( subMyDict1->is_a_type_of(MyDict1), 'subMyDict1 type of MyDict1');
ok ( subMyDict1->is_a_type_of(subMyDict1), 'subMyDict1 type of subMyDict1');
ok ( subMyDict1->is_a_type_of(MyDict2), 'subMyDict1 type of MyDict2');
ok ( MyDict4->is_a_type_of(HashRef), 'MyDict4 is_a_type_of HashRef');
ok ( MyDict4->is_a_type_of(Dict), 'MyDict4 is_a_type_of Dict');
ok (!MyDict4->is_a_type_of(Tuple), 'MyDict4 NOT is_a_type_of Tuple');
ok (!MyDict4->is_a_type_of(MyDict2), 'MyDict4 NOT is_a_type_of MyDict2');
ok ( MyDict2->is_a_type_of(MyDict4), 'MyDict2 is_a_type_of MyDict4');
ok (!MyDict4->is_a_type_of(MyDict3), 'MyDict4 NOT is_a_type_of MyDict3');


ok ( MyTuple1->is_a_type_of(Tuple), 'MyTuple1 is_a_type_of Tuple');
ok (!MyTuple1->is_a_type_of(Dict), 'MyTuple1 NOT is_a_type_of Dict');
ok ( MyTuple1->is_a_type_of(MyTuple2), 'MyTuple1 is_a_type_of MyTuple2');
ok ( MyTuple2->is_a_type_of(MyTuple1), 'MyTuple2 is_a_type_of MyTuple1');
ok (!MyTuple1->is_a_type_of(MyTuple3), 'MyTuple1 NOT is_a_type_of MyTuple3');
ok (!MyTuple2->is_a_type_of(MyTuple3), 'MyTuple2 NOT is_a_type_of MyTuple3');

## is_subtype_of

ok ( not((Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]])->equals( Tuple[Tuple[ Item, Item ], Dict[]] )), "tuple of tuple" );
ok ( (Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]])->equals( Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]] ), "tuple of tuple" );
ok ( (Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]])->is_a_type_of( Tuple[Tuple[ Item, Item ], Dict[]] ), "tuple of tuple" );
ok ( (Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]])->is_a_type_of( Tuple[Tuple[ Item, Item ], Dict[]] ), "tuple of tuple" );
ok ( (Tuple[Tuple[ class_type('Paper'), class_type('Stone') ], Dict[]])->is_subtype_of( Tuple[Tuple[ Item, Item ], Dict[]] ), "tuple of tuple" );

ok ( MyDict1->is_subtype_of(HashRef), 'MyDict1 is_subtype_of HashRef');
ok ( MyDict1->is_subtype_of(Dict), 'MyDict1 is_subtype_of Dict');
ok ( MyDict1->is_subtype_of(MyDict4), 'MyDict1 is_subtype_of MyDict4');
ok (!MyDict1->is_subtype_of(Tuple), 'MyDict1 NOT is_subtype_of Tuple');
ok (!MyDict1->is_subtype_of(MyDict2), 'MyDict1 NOT is_subtype_of MyDict2');
ok (!MyDict2->is_subtype_of(MyDict1), 'MyDict2 NOT is_subtype_of MyDict1');
ok (!MyDict1->is_subtype_of(MyDict3), 'MyDict1 NOT is_subtype_of MyDict3');
ok (!MyDict2->is_subtype_of(MyDict3), 'MyDict2 NOT is_subtype_of MyDict3');
ok ( subMyDict1->is_subtype_of(Dict), 'subMyDict1 is_subtype_of Dict');
ok ( subMyDict1->is_subtype_of(MyDict1), 'subMyDict1 is_subtype_of MyDict1');
ok (!subMyDict1->is_subtype_of(subMyDict1), 'subMyDict1 NOT is_subtype_of subMyDict1');
ok ( subMyDict1->is_subtype_of(MyDict2), 'subMyDict1 is_subtype_of MyDict2');

ok ( MyTuple1->is_subtype_of(Tuple), 'MyTuple1 is_subtype_of Tuple');
ok (!MyTuple1->is_subtype_of(Dict), 'MyTuple1 NOT is_subtype_of Dict');
ok (!MyTuple1->is_subtype_of(MyTuple2), 'MyTuple1 is_subtype_of MyTuple2');
ok (!MyTuple2->is_subtype_of(MyTuple1), 'MyTuple2 is_subtype_of MyTuple1');
ok (!MyTuple1->is_subtype_of(MyTuple3), 'MyTuple1 NOT is_subtype_of MyTuple3');
ok (!MyTuple2->is_subtype_of(MyTuple3), 'MyTuple2 NOT is_subtype_of MyTuple3');

## Test manual parameterizing

PARAMETERIZE: {

    ok (my $int = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Int'), 'Got Int');
    ok (my $str = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Str'), 'Got Str');
    ok (my $hashref = Moose::Util::TypeConstraints::find_or_parse_type_constraint('HashRef[Int]'), 'Got HashRef');

    ## Test Dict->parameterize
    ok (my $test_dict = Dict(), 'Created Test Dict');
    ok (my $person = $test_dict->parameterize(name=>$str, age=>$int), 'Parameterized It');
    ok ($person->check({name=>'John', age=>21}), 'Passed');
    ok ($person->check({age=>25, name=>'User'}), 'Passed');

    ## Test Tuple->parameterize
    ok (my $test_tuple = Tuple(), 'Created Test Tuple');
    ok (my $int_and_hashref = $test_tuple->parameterize($int, $hashref), 'Parameterized It');
    ok ($int_and_hashref->check([1, {key=>2, key2=>3}]), "Passed");
    ok (!$int_and_hashref->check(['a', {key=>2, key2=>3}]), "Not Passed");
    ok (!$int_and_hashref->check([1, {key=>'a', key2=>3}]), "Not Passed");
}
