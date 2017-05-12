# NOTE: This is a test for depricated code. The deprecated code will be removed in 1.100 along with this test.
use Moose;
use Test::More tests => 12;
use Test::Deep qw/cmp_deeply/;
use Data::Dumper;

use lib 'lib';

use MooseX::CoercePerAttribute;
use Moose::Util::TypeConstraints;

has test_str_coerce => (
    is      => 'rw',
    isa     => 'Str',
    traits  => ['CoercePerAttribute'],
    coerce  => {
        Int => sub {
            'TEST'.$_;
            },
        },
    );

has test_int_coerce => (
    is      => 'rw',
    isa     => 'Int',
    traits  => ['CoercePerAttribute'],
    coerce  => {
        Str => sub {
             '2';
            },
        },
    );

has test_arrayref_coerce => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['CoercePerAttribute'],
    coerce  => {
        Str => sub {
            [$_.3];
            },
        },
    );

has test_hashref_coerce => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    traits  => ['CoercePerAttribute'],
    coerce  => {
        Str => sub {
            return {$_ => 4};
            },
        },
    );

has test_multiple_coerce => (
    is      => 'rw',
    isa     => 'HashRef',
    traits  => ['CoercePerAttribute'],
    coerce  => {
        Int => sub {
            {'TEST' => $_}
        },
        ArrayRef => sub {
            return {(shift @{$_}) => 5 },
        },
    },
);

STR_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_str_coerce => '1') };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    is($test->test_str_coerce => '1', 'Str attribute has been coerced correctly');
    }

INT_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_int_coerce => 'TEST' ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    is($test->test_int_coerce => '2', 'Int attribute has been coerced correctly');
    }

ARRAY_REF_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_arrayref_coerce => 'TEST' ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    cmp_deeply($test->test_arrayref_coerce => ['TEST3'], 'ArrayRef attribute has been coerced correctly')
    }

HASH_REF_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_hashref_coerce => 'TEST' ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    cmp_deeply($test->test_hashref_coerce => {'TEST' => 4}, 'HashRef attribute has been coerced correctly')
    }

# These tests check that when we have a case of multiple coercions we use the correct one
MUTIPLE_FROM_ARRAY_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_multiple_coerce => ['TEST'] ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    cmp_deeply($test->test_multiple_coerce => {TEST => 5}, 'Multiple from Array has been coerced correctly')
    }

MULTIPLE_FROM_INT_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_multiple_coerce => 6 ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    cmp_deeply($test->test_multiple_coerce => {TEST => 6}, 'Multiple from Str has been coerced correctly')
    }
