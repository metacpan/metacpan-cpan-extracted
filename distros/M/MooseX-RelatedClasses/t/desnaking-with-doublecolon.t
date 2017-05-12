use Test::More;
use Test::Moose::More 0.014;
use Moose::Util::TypeConstraints 'class_type';

use MooseX::Types::Moose ':all';

{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    with 'MooseX::RelatedClasses' => {
        name => 'TheBaz::Bip',
    };

}
{ package TestClass::TheBaz::Bip; use Moose; use namespace::autoclean }

with_immutable {

    validate_class 'TestClass' => (
        attributes => [
            the_baz__bip_class => {
                reader   => 'the_baz__bip_class',
                isa      => class_type('TestClass::TheBaz::Bip'),
                lazy     => 1,
                init_arg => undef,
            },
            the_baz__bip_class_traits => {
                traits => ['Array'],
                reader    => 'the_baz__bip_class_traits',
                handles => { has_the_baz__bip_class_traits => 'count' },
                builder   => '_build_the_baz__bip_class_traits',
                isa       => ArrayRef[class_type('TestClass::TheBaz::Bip')],
                lazy      => 1,
            },
            original_the_baz__bip_class => {
                reader   => 'original_the_baz__bip_class',
                isa      => class_type('TestClass::TheBaz::Bip'),
                lazy     => 1,
                init_arg => 'the_baz__bip_class',
            },
        ],
        methods => [ qw{ _build_the_baz__bip_class } ],
    );

    my $tc = TestClass->new;

    is $tc->the_baz__bip_class(), 'TestClass::TheBaz::Bip', 'the_baz__bip_class() is correct';

} 'TestClass';

done_testing;
