package MyTest;

use Moo;
with qw( MooX::Role::Reconstruct );

has foo => (
    is        => 'ro',
    default   => 'bar',
    init_arg  => undef,
    keep_init => 1,
);

has baz => (
    is        => 'ro',
    default   => 'baz',
    init_arg  => 'bar',
    keep_init => 1,
);

package main;

use Test::More;

use_ok('MyTest');

my $to1 = new_ok( MyTest => [ foo => 'bar' ], '$to1' );
is( $to1->foo, 'bar', 'default value set in constructor' );

my $to2 = MyTest->reconstruct( foo => 'baz' );
is( $to2->foo, 'bar', 'foo default value kept in reconstructor' );
is( $to2->baz, 'baz', 'baz default value kept in reconstructor' );

my $to3 = MyTest->reconstruct( bar => 'bar' );
is( $to3->baz, 'bar', 'baz value set from bar param' );

done_testing();

exit;

__END__
