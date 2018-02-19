#!/usr/bin/env perl

use strict;
use warnings;
use Test2::Bundle::More;
use Test2::Tools::Compare;

# ABSTRACT: complete Moo::Role::ToJSON tests

BEGIN {
    package My::Advanced;
    use Moo;
    with 'Moo::Role::ToJSON';

    # ABSTRACT: uses all ::ToJSON features

    has bar => (is => 'ro', default => 'bar');
    has foo => (is => 'ro', default => 'foo');

    sub _build_serializable_attributes { [qw/bar foo/] }

    sub is_attribute_serializable {
        my ($self, $attr) = @_;
        return $attr eq 'bar' ? 1 : 0;
    }

    package My::Common;
    use Moo;
    with 'Moo::Role::ToJSON';

    # ABSTRACT: common use cases for ::ToJSON

    has bar => (is => 'ro', default => 'bar');
    has foo => (is => 'ro', default => 'foo');

    sub _build_serializable_attributes { [qw/foo/] }

    package My::Minimal;
    use Moo;
    with 'Moo::Role::ToJSON';
}

subtest advanced_class => \&test_advanced_class;
subtest basic_class    => \&test_basic_class;
subtest minimal_class  => \&test_minimal_class;

done_testing;

sub test_advanced_class {
    my $class = My::Advanced->new();
    is $class->TO_JSON => {bar => 'bar'}, 'only bar is serializable';
}

sub test_basic_class {
    my $class = My::Common->new();
    is $class->TO_JSON => {foo => 'foo'}, 'only foo serializes';

    $class = My::Common->new( serializable_attributes => [qw/foo bar/] );
    is $class->TO_JSON => { foo => 'foo', bar => 'bar' },
        'explicitly set serializable attributes on instantiation.';
}

sub test_minimal_class {
    my $class = My::Minimal->new();
    is $class->TO_JSON => {};
}
