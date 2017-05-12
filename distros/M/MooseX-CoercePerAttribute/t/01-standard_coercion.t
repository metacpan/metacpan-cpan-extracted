use strict;
use warnings;

use Test::Deep qw/cmp_deeply/;
use Test::More tests => 10;
use Moose;
use Moose::Util::TypeConstraints;

use lib 'lib';

use MooseX::CoercePerAttribute;

subtype 'TestStr', as 'Str';
coerce 'TestStr',
    from 'Int',
    via {
        $_ = 'TEST'.$_;
        };

subtype 'TestInt', as 'Int';
coerce 'TestInt', from 'Str',
    via {
        $_ = '2'
        };

subtype 'TestClass::TestArrayRef', as 'ArrayRef[Str]';
coerce 'TestClass::TestArrayRef', from 'Str',
    via {
        [$_.3];
        };

subtype 'TestClass::TestHashRef', as 'HashRef[Str]';
coerce 'TestClass::TestHashRef', from 'Str',
    via {
        return {$_ => 4};
        };

coerce 'TestStr', from 'ArrayRef',
    via {
        return shift @{$_};
        };

has test_str_coerce         => (is => 'ro', isa => 'TestStr',                   coerce => 1);
has test_int_coerce         => (is => 'ro', isa => 'TestInt',                   coerce => 1);
has test_arrayref_coerce    => (is => 'ro', isa => 'TestClass::TestArrayRef',   coerce => 1);
has test_hashref_coerce     => (is => 'ro', isa => 'TestClass::TestHashRef',    coerce => 1);
has test_str_from_array_coerce => (is => 'ro', isa => 'TestStr', coerce => 1);

STR_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_str_coerce => '1') };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    is($test->test_str_coerce => '1', 'Coercion worked correctly');
    }

INT_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_int_coerce => 'TEST' ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    is($test->test_int_coerce => '2', 'Test attribute has been coerced correctly');
    }

ARRAY_REF_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_arrayref_coerce => 'TEST' ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    cmp_deeply($test->test_arrayref_coerce => ['TEST3'], 'Coercion worked correctly')
    }

HASH_REF_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_hashref_coerce => 'TEST' ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    cmp_deeply($test->test_hashref_coerce => {'TEST' => 4}, 'Coerceion worked correctly')
    }

# This test check that when we have a case of multiple coercions we use the correct one
STR_FROM_ARRAY_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_str_from_array_coerce => ['TEST'] ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    is($test->test_str_from_array_coerce => 'TEST', 'Coerceion worked correctly')
    }

