use Test::More;
use Test::Moose::More 0.014;
use Test::Fatal;
use Moose::Util::TypeConstraints 'class_type';

use MooseX::Types::Moose ':all';

{
    package TestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::RelatedClasses;

    related_class name => 'Baz';
    related_class name => 'Kraken', private => 1;
}
{
    package ShortTestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::RelatedClasses;

    related_class 'Baz',      namespace => 'TestClass';
    related_class ['Kraken'], namespace => 'TestClass', private => 1;
}
{
    package CustomNameTestClass;

    use Moose;
    use namespace::autoclean;
    use MooseX::RelatedClasses;

    related_class { 'Baz'    => 'baz' },    namespace => 'TestClass';
    related_class { 'Kraken' => 'kraken' }, namespace => 'TestClass', private => 1;
}

{ package TestClass::Baz;    use Moose; use namespace::autoclean                           }
{ package TestClass::Kraken; use Moose; use namespace::autoclean                           }
{ package TestClass::Bar;    use Moose; use namespace::autoclean; extends 'TestClass::Baz' }

for my $test_class (qw(TestClass ShortTestClass CustomNameTestClass)) {
    with_immutable {

        validate_class $test_class => (
            attributes => [
                baz_class => {
                    reader   => 'baz_class',
                    isa      => class_type('TestClass::Baz'),
                    lazy     => 1,
                    init_arg => undef,
                },
                baz_class_traits => {
                    traits  => ['Array'],
                    reader  => 'baz_class_traits',
                    handles => { has_baz_class_traits => 'count' },
                    builder => '_build_baz_class_traits',
                    isa     => ArrayRef[class_type('TestClass::Baz')],
                    lazy    => 1,
                },
                original_baz_class => {
                    reader   => 'original_baz_class',
                    isa      => class_type('TestClass::Baz'),
                    lazy     => 1,
                    init_arg => 'baz_class',
                },

                # private
                _kraken_class => {
                    reader   => '_kraken_class',
                    isa      => class_type('TestClass::Kraken'),
                    lazy     => 1,
                    init_arg => undef,
                },
                _kraken_class_traits => {
                    traits  => ['Array'],
                    reader  => '_kraken_class_traits',
                    handles => { _has_kraken_class_traits => 'count' },
                    builder => '_build__kraken_class_traits',
                    isa     => ArrayRef[class_type('TestClass::Kraken')],
                    lazy    => 1,
                },
                _original_kraken_class => {
                    reader   => '_original_kraken_class',
                    isa      => class_type('TestClass::Kraken'),
                    lazy     => 1,
                    init_arg => '_kraken_class',
                },
            ],
            methods => [ qw{ _build_baz_class _build__kraken_class} ],
        );

        my $obj = $test_class->new;

        is $obj->baz_class(),     'TestClass::Baz',    "$test_class->baz_class() is correct";
        is $obj->_kraken_class(), 'TestClass::Kraken', "$test_class->_kraken_class() is correct";

        my $dies = exception { $test_class->new(baz_class => 'TestClass::Kraken') };
        ok $dies, 'baz_class dies when attempting to set it to an incorrect class';

        is
            exception { $test_class->new(baz_class => 'TestClass::Bar')->baz_class },
            undef,
            'attribute lives on subclass via constructor',
            ;

    } $test_class;
}

done_testing;
