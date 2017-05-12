use strict;
use warnings;
use Test::More 0.88;

BEGIN {
    package MooseX::Singleton::Test;
    use MooseX::Singleton;

    has bag => (
        is      => 'rw',
        isa     => 'HashRef[Int]',
        default => sub { { default => 42 } },
    );

    sub distinct_keys {
        my $self = shift;
        scalar keys %{ $self->bag };
    }

    sub clear {
        my $self = shift;
        $self->bag( {} );
    }

    sub add {
        my $self  = shift;
        my $key   = shift;
        my $value = @_ ? shift : 1;

        $self->bag->{$key} += $value;
    }
}

my $mst = MooseX::Singleton::Test->instance;
isa_ok( $mst, 'MooseX::Singleton::Test',
    'Singleton->instance returns a real instance' );

is( $mst->distinct_keys, 1, "default keys" );

$mst->add( foo => 10 );
is( $mst->distinct_keys, 2, "added key" );

$mst->add( bar => 5 );
is( $mst->distinct_keys, 3, "added another key" );

my $mst2 = MooseX::Singleton::Test->instance;
is( $mst, $mst2, 'instances are the same object' );
isa_ok( $mst2, 'MooseX::Singleton::Test',
    'Singleton->instance returns a real instance' );

is( $mst2->distinct_keys, 3, "keys from before" );

$mst->add( baz => 2 );

is( $mst->distinct_keys,  4, "attributes are shared even after ->instance" );
is( $mst2->distinct_keys, 4, "attributes are shared even after ->instance" );

is( MooseX::Singleton::Test->distinct_keys, 4, "Package->reader works" );

MooseX::Singleton::Test->add( quux => 9000 );

is( $mst->distinct_keys,                    5, "Package->add works" );
is( $mst2->distinct_keys,                   5, "Package->add works" );
is( MooseX::Singleton::Test->distinct_keys, 5, "Package->add works" );

MooseX::Singleton::Test->clear;

is( $mst->distinct_keys,                    0, "Package->clear works" );
is( $mst2->distinct_keys,                   0, "Package->clear works" );
is( MooseX::Singleton::Test->distinct_keys, 0, "Package->clear works" );

MooseX::Singleton::Test->_clear_instance;
$mst = $mst2 = undef;
is( MooseX::Singleton::Test->instance->distinct_keys, 1, "back to the default" );

done_testing;
