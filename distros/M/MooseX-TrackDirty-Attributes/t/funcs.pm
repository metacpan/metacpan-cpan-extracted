#
# This file is part of MooseX-TrackDirty-Attributes
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

sub do_tests {

    note 'class...';
    validate_class TestClass => (
        attributes => [ qw{ foo                                    } ],
        methods    => [ qw{ foo foo_length foo_append foo_is_dirty } ],
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
    note $method->original_fully_qualified_name;

    my $attr = TestClass->meta->get_attribute('foo');

    note q{attribute foo's meta off TestClass...};
    validate_class ref $attr => (
            #MooseX::TrackDirty::Attributes::Trait::Attribute::Native::Trait
        does => [ qw{
            Moose::Meta::Attribute::Native::Trait::String
            MooseX::TrackDirty::Attributes::Trait::Attribute
        } ],
    );

    does_ok
        $attr,
        'MooseX::TrackDirty::Attributes::Trait::Attribute::Native::Trait',
        ;
    {
        my $test = TestClass->new;

        ok !$test->foo_is_dirty, 'foo is not dirty yet';
        $test->foo('dirty now!');
        is $test->foo, 'dirty now!', 'foo set correctly';
        ok $test->foo_is_dirty, 'foo is dirty now';
    }
    {
        my $test = TestClass->new(foo => 'initial');
        ok !$test->foo_is_dirty, 'foo is not dirty yet';
        is $test->foo, 'initial', 'foo set correctly';
        #$test->foo('dirty now!');
        $test->foo_append(' dirty!');
        is $test->foo, 'initial dirty!', 'foo set correctly';
        ok $test->foo_is_dirty, 'foo is dirty now';
    }

}

!!42;
