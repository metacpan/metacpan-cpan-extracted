use Test::More;
use Test::Moose::More 0.014;
use Moose::Util::TypeConstraints 'class_type';

use MooseX::Types::Moose ':all';

{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    # with default decamelization
    with 'MooseX::RelatedClasses' => {
        names     => [ 'Net::Amazon::EC2' ],
        namespace => undef,
    };

    # with explicit decamelization
    with 'MooseX::RelatedClasses' => {
        names     => { 'Net::Amazon::EC2' => 'net__amazon__ec2' },
        namespace => undef,
    };
}

with_immutable {

    validate_class 'TestClass' => (
        attributes => [

            # with default decamelization
            net__amazon__e_c2_class => {
                reader   => 'net__amazon__e_c2_class',
                isa      => class_type('TestClass::TheBaz::Bip'),
                lazy     => 1,
                init_arg => undef,
            },
            net__amazon__e_c2_class_traits => {
                traits => ['Array'],
                reader    => 'net__amazon__e_c2_class_traits',
                handles => { has_net__amazon__e_c2_class_traits => 'count' },
                builder   => '_build_net__amazon__e_c2_class_traits',
                isa       => ArrayRef[class_type('TestClass::TheBaz::Bip')],
                lazy      => 1,
            },
            original_net__amazon__e_c2_class => {
                reader   => 'original_net__amazon__e_c2_class',
                isa      => class_type('TestClass::TheBaz::Bip'),
                lazy     => 1,
                init_arg => 'net__amazon__e_c2_class',
            },

            # with specified decamelization
            net__amazon__ec2_class => {
                reader   => 'net__amazon__ec2_class',
                isa      => class_type('TestClass::TheBaz::Bip'),
                lazy     => 1,
                init_arg => undef,
            },
            net__amazon__ec2_class_traits => {
                traits => ['Array'],
                reader    => 'net__amazon__ec2_class_traits',
                handles => { has_net__amazon__ec2_class_traits => 'count' },
                builder   => '_build_net__amazon__ec2_class_traits',
                isa       => ArrayRef[class_type('TestClass::TheBaz::Bip')],
                lazy      => 1,
            },
            original_net__amazon__ec2_class => {
                reader   => 'original_net__amazon__ec2_class',
                isa      => class_type('TestClass::TheBaz::Bip'),
                lazy     => 1,
                init_arg => 'net__amazon__ec2_class',
            },
        ],
        methods => [ qw{
            net__amazon__e_c2_class
            _build_net__amazon__e_c2_class

            net__amazon__e_c2_class_traits
            has_net__amazon__e_c2_class_traits
            _build_net__amazon__e_c2_class_traits

            original_net__amazon__e_c2_class

            net__amazon__ec2_class
            _build_net__amazon__ec2_class

            net__amazon__ec2_class_traits
            has_net__amazon__ec2_class_traits
            _build_net__amazon__ec2_class_traits

            original_net__amazon__ec2_class
        } ],
    );

    my $tc = TestClass->new;

} 'TestClass';

done_testing;
