package MyTest;

use Moo;
with qw( MooX::Role::Reconstruct );

has foo => (
    is       => 'ro',
    default  => 'foo',
    init_arg => undef,
);

has bar => (
    is       => 'ro',
    default  => 'bar',
    init_arg => 'baz',
);

package main;

use Test::More;

use_ok('MyTest');

my $test_obj = new_ok( MyTest => [ baz => 'baz' ], '$test_obj' );
is( $test_obj->foo, 'foo', 'foo default value set' );
is( $test_obj->bar, 'baz', 'bar value set from baz param' );

my $to2 = MyTest->reconstruct( foo => 'baz', baz => 'foo' );
isa_ok( $to2, 'MyTest', 'reconstucted $to2' );
is( $to2->foo, 'baz', 'foo value from reconstructor set' );
is( $to2->bar, 'bar', 'bar init_arg baz ignored' );

done_testing();

exit;

__END__
