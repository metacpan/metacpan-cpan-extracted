use strict;
use warnings;

use autobox::Core;

use Test::More;
use Test::Moose::More 0.014;
use Moose::Util::TypeConstraints 'class_type';
use MooseX::Types::Moose ':all';

# debugging...
#use Smart::Comments '###';

{
    package TestClass;

    use Moose;
    use namespace::autoclean;

    with 'MooseX::RelatedClasses' => {
        name      => 'Test::More',
        namespace => undef,
    };

}

with_immutable {

    validate_class 'TestClass' => (
        related(q{} => 'Test::More')->flatten,
    );

    my $tc = TestClass->new;
    is $tc->test__more_class(), 'Test::More', 'test_more_class() is correct';

} 'TestClass';


sub related {
    my ($namespace, $related) = @_;

    $namespace    .= '::' if $namespace ne q{};
    my $class_name = $namespace . $related;
    my $class_type = class_type $class_name;
    my $flat       = $related->split(qr/::/)->join('__')->lc;

    my $test_hash = {
        attributes => [
            (
                "${flat}_class" => {
                    reader   => "${flat}_class",
                    isa      => $class_type,
                    lazy     => 1,
                    init_arg => undef,
                },
                "${flat}_class_traits" => {
                    traits  => ['Array'],
                    reader  => "${flat}_class_traits",
                    handles => { "has_${flat}_class_traits" => 'count' },
                    builder => "_build_${flat}_class_traits",
                    isa     => ArrayRef[$class_type],
                    lazy    => 1,
                },
                "original_${flat}_class" => {
                    reader   => "original_${flat}_class",
                    isa      => $class_type,
                    lazy     => 1,
                    init_arg => "${flat}_class",
                },
            ),
        ],
        methods => [ "_build_${flat}_class" ],
    };

    ### $test_hash
    return $test_hash;
}

done_testing;
