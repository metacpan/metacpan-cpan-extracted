use Moose;
use Test::More tests => 12;
use Test::Deep q/cmp_deeply/;
use Data::Dumper;

use lib 'lib';

use MooseX::CoercePerAttribute;
use Moose::Util::TypeConstraints;

has test_str_coerce => (
    is      => 'rw',
    isa     => 'Str',
    traits  => ['CoercePerAttribute'],
    coerce  => [
        sub {
            coerce $_[0], from 'Int', via { 'TEST'.$_ },
            },
        ],
    );

has test_int_coerce => (
    is      => 'rw',
    isa     => 'Int',
    traits  => ['CoercePerAttribute'],
    coerce  => [
        sub {
            coerce $_[0], from 'Str', via { '2' },
            },
        ],
    );

has test_arrayref_coerce => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['CoercePerAttribute'],
    coerce  => [
        sub {
            coerce $_[0], from 'Str', via { [$_.3] },
            },
        ],
    );

has test_hashref_coerce => (
    is      => 'rw',
    isa     => 'HashRef[Str]',
    traits  => ['CoercePerAttribute'],
    coerce  => [
        sub {
            coerce $_[0], from 'Str', via { return {$_ => 4}  },
            },
        ],
    );

has test_multiple_coerce => (
    is      => 'rw',
    isa     => 'Str',
    traits  => ['CoercePerAttribute'],
    coerce  => [
        sub {
            coerce $_[0], from 'Int', via { 'TEST'.$_ },
            },
        sub {
            coerce $_[0], from 'ArrayRef', via { (shift @{$_}).5 },
            },
        ],
    );

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

# These tests check that when we have a case of multiple coercions we use the correct one
MUTIPLE_FROM_ARRAY_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_multiple_coerce => ['TEST'] ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    is($test->test_multiple_coerce => 'TEST5', 'Coerceion worked correctly')
    }

MULTIPLE_FROM_STR_COERCION: {
    my $test;
    eval { $test = __PACKAGE__->new( test_multiple_coerce => 6 ) };

    ok(!$@, 'Created TestClass object without errors') || fail(Dumper($@));
    is($test->test_multiple_coerce => '6', 'Coerceion worked correctly')
    }
