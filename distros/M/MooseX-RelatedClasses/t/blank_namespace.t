use strict;
use warnings;

use autobox::Core;

use Test::More;
use Test::Moose::More 0.014;
use Moose::Util::TypeConstraints 'class_type';

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

require 't/funcs.pm' unless eval { require funcs };

with_immutable {

    validate_class 'TestClass' => (
        related(q{} => 'Test::More')->flatten,
    );

    my $tc = TestClass->new;
    is $tc->test__more_class(), 'Test::More', 'test_more_class() is correct';

} 'TestClass';

done_testing;
