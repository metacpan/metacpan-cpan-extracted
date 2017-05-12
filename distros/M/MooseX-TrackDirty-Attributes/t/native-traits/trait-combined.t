use strict;
use warnings;

{
    package TestClass::Trait;
    use Moose::Role;
    #use MooseX::TrackDirty::Attributes 'TrackDirty';

    with 'MooseX::TrackDirty::Attributes::Trait::Attribute';

    sub some_other_method { 'w00t!' }
}
{
    package TestClass;
    use Moose;

    has foo => (

        traits  => [ 'TestClass::Trait', 'String' ],
        is      => 'rw',
        isa     => 'Str',
        clearer => 'clear_foo',
        default => q{},

        is_dirty => 'foo_is_dirty',

        handles => {

            foo_length => 'length',
            foo_append => 'append',
        },
    );
}

use Test::More;
use Test::Moose::More 0.005;

require 't/funcs.pm' unless eval { require funcs };

note 'TestClass::Trait checks...';
validate_role 'TestClass::Trait' => (
    does    => [ qw{ MooseX::TrackDirty::Attributes::Trait::Attribute } ],
    methods => [ qw{ some_other_method }                                ],
);

{
    can_ok 'TestClass', 'foo_is_dirty';

    my $meta = TestClass::Trait->meta;
    #my $foo_meta   = TestClass->meta->get_attribute('foo')->meta;

    #for my $meta ($trait_meta, $foo_meta) {
    my @roles = map { $_->name } $meta->calculate_all_roles;

    note ref $meta;
    note explain [ @roles ];

    does_ok
        $meta,
        'MooseX::TrackDirty::Attributes::Trait::Role',
        ;

    does_ok
        $meta->application_to_class_class,
        'MooseX::TrackDirty::Attributes::Trait::Role::Application::ToClass',
        ;

    does_ok
        $meta->application_to_role_class,
        'MooseX::TrackDirty::Attributes::Trait::Role::Application::ToRole',
        ;
    #}
}

with_immutable {

    note 'our specialized foo tests...';
    my $foo = TestClass->meta->get_attribute('foo');

    does_ok($foo,       [ 'MooseX::TrackDirty::Attributes::Trait::Attribute' ]);
    does_ok($foo->meta, [ 'MooseX::TrackDirty::Attributes::Trait::Class'     ]);

    validate_class ref $foo => (

        isa     => [ qw{ Moose::Meta::Attribute } ],
        does    => [ qw{ TestClass::Trait       } ],
        methods => [ qw{ some_other_method      } ],
    );

    do_tests();

} 'TestClass';

done_testing;
