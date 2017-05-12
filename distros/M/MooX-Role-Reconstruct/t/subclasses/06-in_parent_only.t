$| = 1;

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

package MyTest::Subclass;

use Moo;
extends qw( MyTest );

has fog => (
    is       => 'ro',
    default  => 'fog',
    init_arg => undef,
);

package main;

use Test::More;

use_ok('MyTest::Subclass');
can_ok( 'MyTest::Subclass', 'reconstruct' );

my $test_obj = new_ok( 'MyTest::Subclass' => [ baz => 'baz' ], '$test_obj' );
is( $test_obj->foo, 'foo', 'foo default value set' );
is( $test_obj->bar, 'baz', 'bar value set from baz param' );
is( $test_obj->fog, 'fog', 'fog default value set' );

my $to2 =
  MyTest::Subclass->reconstruct( foo => 'baz', baz => 'foo', fog => 'foo' );
isa_ok( $to2, 'MyTest',           'reconstucted $to2' );
isa_ok( $to2, 'MyTest::Subclass', 'reconstucted $to2' );
is( $to2->foo, 'baz', 'foo value set from reconstructor' );
is( $to2->bar, 'bar', 'bar init_arg baz ignored' );
is( $to2->fog, 'foo', 'fog value set from reconstructor' );

done_testing();

exit;

__END__
