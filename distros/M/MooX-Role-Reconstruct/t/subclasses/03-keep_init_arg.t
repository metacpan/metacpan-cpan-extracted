package MyTest;

use Moo;
with qw( MooX::Role::Reconstruct );

has foo => (
    is        => 'ro',
    default   => 'foo',
    init_arg  => undef,
    keep_init => 1,
);

has baz => (
    is        => 'ro',
    default   => 'baz',
    init_arg  => 'bar',
    keep_init => 1,
);

package MyTest::Subclass;

use Moo;
extends qw( MyTest );
with qw( MooX::Role::Reconstruct );

has fog => (
    is        => 'ro',
    default   => 'fog',
    init_arg  => undef,
    keep_init => 1,
);

package main;

use Test::More;

use_ok('MyTest::Subclass');

my $to1 =
  new_ok( 'MyTest::Subclass' => [ foo => 'bar', bar => 'bar' ], '$to1' );
is( $to1->foo, 'foo', 'foo value set to default in constructor' );
is( $to1->baz, 'bar', 'baz value set by bar in constructor' );
is( $to1->fog, 'fog', 'fog value set to default in constructor' );

my $to2 = MyTest::Subclass->reconstruct( foo => 'baz', baz => 'bar' );
is( $to2->foo, 'foo', 'foo default value kept in reconstructor' );
is( $to2->baz, 'baz', 'baz default value kept in reconstructor' );
is( $to2->fog, 'fog', 'baz default value kept in reconstructor' );

my $to3 = MyTest::Subclass->reconstruct( bar => 'bar' );
is( $to3->baz, 'bar', 'baz value set from bar param' );

done_testing();

exit;

__END__
