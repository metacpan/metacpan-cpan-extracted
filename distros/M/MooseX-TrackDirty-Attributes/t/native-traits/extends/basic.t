use strict;
use warnings;

{
    package TestClass::First;
    use Moose;

    has foo => (

        traits  => [ 'String' ],
        is      => 'rw',
        isa     => 'Str',
        default => 'default',
        handles => {

            foo_length => 'length',
            foo_append => 'append',
        },
    );
}
{
    package TestClass;
    use Moose;
    use MooseX::TrackDirty::Attributes;

    extends 'TestClass::First';

    has '+foo' => (

        traits  => [ TrackDirty ],
    );
}

use Test::More skip_all => 'needs _process_options() to be called';
use Test::Moose::More 0.005;

require 't/funcs.pm' unless eval { require funcs };

with_immutable { with_immutable { do_tests() } 'TestClass' } 'TestClass::First';

#do_tests();

done_testing;

__END__
note 'class...';
validate_class TestClass => (
    attributes => [ qw{ foo }                       ],
    methods    => [ qw{ foo foo_length foo_append } ],
);

my $trackdirty_role = 'MooseX::TrackDirty::Attributes::Trait::Attribute';

note q{trackdirty role metarole classes...};
validate_class $trackdirty_role->meta->application_to_class_class() => (
    does => [ qw{
        MooseX::TrackDirty::Attributes::Trait::Role::Application::ToClass
    } ],
);

note 'check our native trait accessors for our traits...';
my $method = TestClass->meta->get_method('foo_append');
validate_class ref $method => (
    does => [ qw{
        Moose::Meta::Method::Accessor::Native::Writer
        Moose::Meta::Method::Accessor::Native::String::append
        MooseX::TrackDirty::Attributes::Trait::Method::Accessor::Native
    } ],
);

my $attr = TestClass->meta->get_attribute('foo');

note q{attribute foo's meta off TestClass...};
validate_class ref $attr => (
    does => [ qw{
        Moose::Meta::Attribute::Native::Trait::String
        MooseX::TrackDirty::Attributes::Trait::Attribute::Native::Trait
        MooseX::TrackDirty::Attributes::Trait::Attribute
    } ],
);

{
    note 'Testing instance w/o using native trait accessors';
    my $test = TestClass->new;
    ok !$test->foo_is_dirty, 'foo is not dirty yet';
    $test->foo('dirty now!');
    is $test->foo, 'dirty now!', 'foo set correctly';
    ok $test->foo_is_dirty, 'foo is dirty now';
}
{
    note 'Testing instance using native trait accessors';
    my $test = TestClass->new(foo => 'initial');
    ok !$test->foo_is_dirty, 'foo is not dirty yet';
    is $test->foo, 'initial', 'foo set correctly';
    $test->foo_append(' dirty!');
    is $test->foo, 'initial dirty!', 'foo set correctly';
    ok $test->foo_is_dirty, 'foo is dirty now';
}

done_testing;

__END__

note q{attribute foo's metarole classes...};
validate_class do { TestClass->meta->application_to_class_class()} => (
    does => [ qw{
        MooseX::TrackDirty::Attributes::Trait::Role::Application::ToClass
    } ],
);

