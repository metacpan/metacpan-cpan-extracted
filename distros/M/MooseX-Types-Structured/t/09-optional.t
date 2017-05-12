use strict;
use warnings;

use Test::More tests=>46;
use Test::Fatal;
use Moose::Util::TypeConstraints ();
use MooseX::Types::Structured qw(Optional);

APITEST: {

    ok my $Optional = Moose::Util::TypeConstraints::find_or_parse_type_constraint('MooseX::Types::Structured::Optional')
     => 'Got Optional';

    isa_ok $Optional
     => 'Moose::Meta::TypeConstraint::Parameterizable';

    ok my $int = Moose::Util::TypeConstraints::find_or_parse_type_constraint('Int')
     => 'Got Int';

    ok my $arrayref = Moose::Util::TypeConstraints::find_or_parse_type_constraint('ArrayRef[Int]')
     => 'Got ArrayRef[Int]';

    BASIC: {
        ok my $Optional_Int = $Optional->parameterize($int), 'Parameterized Int';
        ok my $Optional_ArrayRef = $Optional->parameterize($arrayref), 'Parameterized ArrayRef';

        ok $Optional_Int->check() => 'Optional is allowed to not exist';

        ok !$Optional_Int->check(undef) => 'Optional is NOT allowed to be undef';
        ok $Optional_Int->check(199) => 'Correctly validates 199';
        ok !$Optional_Int->check("a") => 'Correctly fails "a"';

        ok $Optional_ArrayRef->check() => 'Optional is allowed to not exist';
        ok !$Optional_ArrayRef->check(undef) => 'Optional is NOT allowed to be undef';
        ok $Optional_ArrayRef->check([1,2,3]) => 'Correctly validates [1,2,3]';
        ok !$Optional_ArrayRef->check("a") => 'Correctly fails "a"';
        ok !$Optional_ArrayRef->check(["a","b"]) => 'Correctly fails ["a","b"]';
    }

    SUBREF: {
        ok my $Optional_Int = Optional->parameterize($int),'Parameterized Int';
        ok my $Optional_ArrayRef = Optional->parameterize($arrayref), 'Parameterized ArrayRef';

        ok $Optional_Int->check() => 'Optional is allowed to not exist';

        ok !$Optional_Int->check(undef) => 'Optional is NOT allowed to be undef';
        ok $Optional_Int->check(199) => 'Correctly validates 199';
        ok !$Optional_Int->check("a") => 'Correctly fails "a"';

        ok $Optional_ArrayRef->check() => 'Optional is allowed to not exist';
        ok !$Optional_ArrayRef->check(undef) => 'Optional is NOT allowed to be undef';
        ok $Optional_ArrayRef->check([1,2,3]) => 'Correctly validates [1,2,3]';
        ok !$Optional_ArrayRef->check("a") => 'Correctly fails "a"';
        ok !$Optional_ArrayRef->check(["a","b"]) => 'Correctly fails ["a","b"]';
    }
}

OBJECTTEST: {
    package Test::MooseX::Meta::TypeConstraint::Structured::Optional;

    use Moose;
    use MooseX::Types::Structured qw(Dict Tuple Optional);
    use MooseX::Types::Moose qw(Int Str Object ArrayRef HashRef Maybe);
    use MooseX::Types -declare => [qw(
        MoreThanFive TupleOptional1 TupleOptional2 Gender DictOptional1 Insane
    )];

    subtype MoreThanFive,
     as Int,
     where { $_ > 5};

    enum Gender,
     [ qw/male female transgendered/ ];

    subtype TupleOptional1() =>
        as Tuple[Int, MoreThanFive, Optional[Str|Object]];

    subtype TupleOptional2,
        as Tuple[Int, MoreThanFive, Optional[HashRef[Int|Object]]];

    subtype DictOptional1,
        as Dict[name=>Str, age=>Int, gender=>Optional[Gender]];

    subtype Insane,
        as Tuple[
            Int,
            Optional[Str|Object],
            DictOptional1,
            Optional[ArrayRef[Int]]
        ];

    has 'TupleOptional1Attr' => (is=>'rw', isa=>TupleOptional1);
    has 'TupleOptional2Attr' => (is=>'rw', isa=>TupleOptional2);
    has 'DictOptional1Attr' => (is=>'rw', isa=>DictOptional1);
    has 'InsaneAttr' => (is=>'rw', isa=>Insane);
}

ok my $obj = Test::MooseX::Meta::TypeConstraint::Structured::Optional->new
 => 'Instantiated new test class.';

isa_ok $obj => 'Test::MooseX::Meta::TypeConstraint::Structured::Optional'
 => 'Created correct object type.';

# Test Insane

is( exception {
    $obj->InsaneAttr([1,"hello",{name=>"John",age=>39,gender=>"male"},[1,2,3]]);
} => undef, 'Set InsaneAttr attribute without error [1,"hello",{name=>"John",age=>39,gender=>"male"},[1,2,3]]');

is( exception {
    $obj->InsaneAttr([1,$obj,{name=>"John",age=>39},[1,2,3]]);
} => undef, 'Set InsaneAttr attribute without error [1,$obj,{name=>"John",age=>39},[1,2,3]]');

is( exception {
    $obj->InsaneAttr([1,$obj,{name=>"John",age=>39}]);
} => undef, 'Set InsaneAttr attribute without error [1,$obj,{name=>"John",age=>39}]');

like( exception {
    $obj->InsaneAttr([1,$obj,{name=>"John",age=>39},[qw/a b c/]]);
}, qr/Attribute \(InsaneAttr\) does not pass the type constraint/
 => q{InsaneAttr correctly fails [1,$obj,{name=>"John",age=>39},[qw/a b c/]]});

like( exception {
    $obj->InsaneAttr([1,"hello",{name=>"John",age=>39,gender=>undef},[1,2,3]]);
}, qr/Attribute \(InsaneAttr\) does not pass the type constraint/
 => q{InsaneAttr correctly fails [1,"hello",{name=>"John",age=>39,gender=>undef},[1,2,3]]});

# Test TupleOptional1Attr

is( exception {
    $obj->TupleOptional1Attr([1,10,"hello"]);
} => undef, 'Set TupleOptional1Attr attribute without error [1,10,"hello"]');

is( exception {
    $obj->TupleOptional1Attr([1,10,$obj]);
} => undef, 'Set TupleOptional1Attr attribute without error [1,10,$obj]');

is( exception {
    $obj->TupleOptional1Attr([1,10]);
} => undef, 'Set TupleOptional1Attr attribute without error [1,10]');

like( exception {
    $obj->TupleOptional1Attr([1,10,[1,2,3]]);
}, qr/Attribute \(TupleOptional1Attr\) does not pass the type constraint/
 => q{TupleOptional1Attr correctly fails [1,10,[1,2,3]]});

like( exception {
    $obj->TupleOptional1Attr([1,10,undef]);
}, qr/Attribute \(TupleOptional1Attr\) does not pass the type constraint/
 => q{TupleOptional1Attr correctly fails [1,10,undef]});

# Test TupleOptional2Attr

is( exception {
    $obj->TupleOptional2Attr([1,10,{key1=>1,key2=>$obj}]);
} => undef, 'Set TupleOptional2Attr attribute without error [1,10,{key1=>1,key2=>$obj}]');

is( exception {
    $obj->TupleOptional2Attr([1,10]);
} => undef, 'Set TupleOptional2Attr attribute without error [1,10]');

like( exception {
    $obj->TupleOptional2Attr([1,10,[1,2,3]]);
}, qr/Attribute \(TupleOptional2Attr\) does not pass the type constraint/
 => q{TupleOptional2Attr correctly fails [1,10,[1,2,3]]});

like( exception {
    $obj->TupleOptional2Attr([1,10,undef]);
}, qr/Attribute \(TupleOptional2Attr\) does not pass the type constraint/
 => q{TupleOptional2Attr correctly fails [1,10,undef]});

# Test DictOptional1Attr: Dict[name=>Str, age=>Int, gender=>Optional[Gender]];

is( exception {
    $obj->DictOptional1Attr({name=>"John",age=>39,gender=>"male"});
} => undef, 'Set DictOptional1Attr attribute without error {name=>"John",age=>39,gender=>"male"}');

is( exception {
    $obj->DictOptional1Attr({name=>"Vanessa",age=>34});
} => undef, 'Set DictOptional1Attr attribute without error {name=>"Vanessa",age=>34}');

like( exception {
    $obj->DictOptional1Attr({name=>"John",age=>39,gender=>undef});
}, qr/Attribute \(DictOptional1Attr\) does not pass the type constraint/
 => q{TupleOptional2Attr correctly fails {name=>"John",age=>39,gender=>undef}});

like( exception {
    $obj->DictOptional1Attr({name=>"John",age=>39,gender=>"aaa"});
}, qr/Attribute \(DictOptional1Attr\) does not pass the type constraint/
 => q{TupleOptional2Attr correctly fails {name=>"John",age=>39,gender=>"aaa"}});
