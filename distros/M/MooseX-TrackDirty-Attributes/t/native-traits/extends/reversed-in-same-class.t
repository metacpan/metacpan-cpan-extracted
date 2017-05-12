use strict;
use warnings;

{
    package TestClass;
    use Moose;
    use MooseX::TrackDirty::Attributes;

    has foo => (

        traits  => [ TrackDirty ],
        is      => 'rw',
        isa     => 'Str',
        default => 'default',
    );

    has '+foo' => (

        traits  => [ 'String' ],
        handles => {

            foo_length => 'length',
            foo_append => 'append',
        },
    );
}

use Test::More;
use Test::Moose::More 0.005;

require 't/funcs.pm' unless eval { require funcs };

do_tests();

done_testing;

__END__

note q{attribute foo's metarole classes...};
validate_class do { TestClass->meta->application_to_class_class()} => (
    does => [ qw{
        MooseX::TrackDirty::Attributes::Trait::Role::Application::ToClass
    } ],
);

