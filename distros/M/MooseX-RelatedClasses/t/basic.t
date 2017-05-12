use Test::More;
use Test::Moose::More 0.045;
use Test::Fatal;
use Moose::Util::TypeConstraints 'class_type';

use MooseX::Types::Moose ':all';

{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    with 'MooseX::RelatedClasses' => {
        name => 'Baz',
    };

    with 'MooseX::RelatedClasses' => {
        name    => 'Kraken',
        private => 1,
    };
}
{ package TestClass::Baz;    use Moose; use namespace::autoclean }
{ package TestClass::Kraken; use Moose; use namespace::autoclean }

{ package TestClass::Bar; use Moose; use namespace::autoclean; extends 'TestClass::Baz' }

with_immutable {

    validate_class 'TestClass' => (
        attributes => [
            baz_class => {
                reader   => 'baz_class',
                isa      => class_type('TestClass::Baz'),
                lazy     => 1,
                init_arg => undef,
            },
            baz_class_traits => {
                traits => ['Array'],
                reader    => 'baz_class_traits',
                handles => { has_baz_class_traits => 'count' },
                builder   => '_build_baz_class_traits',
                isa       => ArrayRef[class_type('TestClass::Baz')],
                lazy      => 1,
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
                traits => ['Array'],
                reader    => '_kraken_class_traits',
                handles => { _has_kraken_class_traits => 'count' },
                builder   => '_build__kraken_class_traits',
                isa       => ArrayRef[class_type('TestClass::Kraken')],
                lazy      => 1,
            },
            _original_kraken_class => {
                reader   => '_original_kraken_class',
                isa      => class_type('TestClass::Kraken'),
                lazy     => 1,
                init_arg => '_kraken_class',
            },
        ],
        methods => [ qw{ _build_baz_class _build__kraken_class} ],

        no_methods => [ qw{ _generate_one_attribute_set related_class related_classes related_namespace } ],
    );

    my $tc = TestClass->new;

    is $tc->baz_class(),     'TestClass::Baz',    'baz_class() is correct';
    is $tc->_kraken_class(), 'TestClass::Kraken', '_kraken_class() is correct';

    my $dies = exception { $tc = TestClass->new(baz_class => 'TestClass::Kraken'); $tc->baz_class };
    ok $dies, 'baz_class dies when attempting to set it to an incorrect class';

    is
        exception { TestClass->new(baz_class => 'TestClass::Bar')->baz_class },
        undef,
        'attribute lives on subclass via constructor',
        ;

} 'TestClass';

done_testing;
