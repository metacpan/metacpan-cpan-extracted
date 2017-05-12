use strict;
use warnings;

use Test::More 0.88;

use Scalar::Util qw(refaddr);

{
    package Bar;
    use Moose;

    with qw(MooseX::Clone);

    has foo => (
        traits => [qw(Clone)],
        isa => "Foo|HashRef",
        is  => "rw",
        default => sub { Foo->new },
    );

    has same => (
        isa => "Foo",
        is  => "rw",
        default => sub { Foo->new },
    );

    has floo => (
        traits => [qw(NoClone)],
        isa => "Int",
        is  => "rw",
    );

    has flar => (
        traits => [qw(Copy)],
        isa    => "HashRef",
        is     => "rw",
        predicate => 'has_flar',
    );

    has blorg => (
        traits => [qw(StorableClone)],
        is     => "rw",
    );

    package Foo;
    use Moose;

    has copy_number => (
        isa => "Int",
        is  => "ro",
        default => 0,
    );

    has some_attr => ( is => "rw", default => "def" );

    sub clone {
        my ( $self, %params ) = @_;

        $self->meta->clone_object( $self, %params, copy_number => $self->copy_number + 1 );
    }
}


my $bar = Bar->new( floo => 3 );

isa_ok( $bar, "Bar" );
isa_ok( $bar->foo, "Foo" );
isa_ok( $bar->same, "Foo" );

is( $bar->floo, 3, "explicit init_arg" );

is( $bar->foo->copy_number, 0, "first copy" );
is( $bar->same->copy_number, 0, "first copy" );

is( $bar->foo->some_attr, 'def', "default value for other attr" );

my $copy = $bar->clone( flar => { blog => [1,2,3] } );

isnt( refaddr($bar), refaddr($copy), "copy" );

is( $copy->floo, undef, "NoClone" );

is( $copy->foo->copy_number, 1, "copy number incremented" );
is( $copy->same->copy_number, 0, "not incremented for uncloned attr" );

is( $copy->foo->some_attr, 'def', "default value for other attr" );

isnt( refaddr($bar->foo), refaddr($copy->foo), "copy" );
is( refaddr($bar->same), refaddr($copy->same), "copy" );

ok( $copy->has_flar, "flar was inserted" );

is( $copy->clone( foo => { some_attr => "laaa" } )->foo->some_attr, "laaa", "Value carried over to recursive call to clone" );

{
    my $hash = { foo => Foo->new };
    my $hash_copy = Bar->new( foo => $hash )->clone->foo;

    isnt( refaddr($hash), refaddr($hash_copy), "hash copied" );
    is_deeply( [ sort keys %$hash ], [ sort keys %$hash_copy ], "hash keys exist in clone" );
    isa_ok($hash_copy->{foo}, "Foo");
    isnt( refaddr($hash->{foo}), refaddr($hash_copy->{foo}), "foo inside hash cloned too" );
    is( $hash_copy->{foo}->copy_number, 1, "copy number" );
}

{
    my $hash = { foo => Foo->new, bar => []  };
    my $hash_copy = Bar->new( flar => $hash )->clone->flar;

    isnt( refaddr($hash), refaddr($hash_copy), "hash copied" );
    is_deeply( [ sort keys %$hash ], [ sort keys %$hash_copy ], "hash keys exist in clone" );
    isa_ok($hash_copy->{foo}, "Foo");
    is( refaddr($hash->{foo}), refaddr($hash_copy->{foo}), "foo inside hash not cloned" );
    is( refaddr($hash->{bar}), refaddr($hash_copy->{bar}), "array inside hash not cloned" );
}

{
    my $foo = Foo->new;
    my $foo_copy = Bar->new( blorg => $foo )->clone->blorg;

    isnt( refaddr($foo), refaddr($foo_copy), "foo copied" );
    is( $foo_copy->copy_number, $foo->copy_number, "but not using ->clone");
}

done_testing;
