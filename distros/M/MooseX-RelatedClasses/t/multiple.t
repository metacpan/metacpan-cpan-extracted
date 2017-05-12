use Test::More;
use Test::Moose::More 0.014;
use Moose::Util::TypeConstraints 'class_type';

use MooseX::Types::Moose ':all';

{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    with 'MooseX::RelatedClasses' => {
        names => [ qw{ Baz Bar Boo } ],
    };

}
{ package TestClass::Baz; use Moose; use namespace::autoclean }
{ package TestClass::Bar; use Moose; use namespace::autoclean }
{ package TestClass::Boo; use Moose; use namespace::autoclean }

with_immutable {

    validate_class 'TestClass' => (
        attributes => [
            do { lc "${_}_class" } => {
                reader   => lc "${_}_class",
                isa      => class_type("TestClass::$_"),
                lazy     => 1,
                init_arg => undef,
            },
            do { lc "${_}_class_traits" } => {
                traits => ['Array'],
                reader    => lc "${_}_class_traits",
                handles => { do { lc "has_${_}_class_traits" } => 'count' },
                builder   => lc "_build_${_}_class_traits",
                isa       => ArrayRef[class_type("TestClass::${_}")],
                lazy      => 1,
            },
            do { lc "original_${_}_class" } => {
                reader   => lc "original_${_}_class",
                isa      => class_type("TestClass::$_"),
                lazy     => 1,
                init_arg => lc "${_}_class",
            },
        ],
        methods => [ lc "_build_${_}_class" ],
    ) for qw{ Baz Bar Boo };

    my $tc = TestClass->new;

    is $tc->baz_class(), 'TestClass::Baz', 'baz_class() is correct';

} 'TestClass';

done_testing;
