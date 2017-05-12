package MyTest;

use Moo;
with qw( MooX::Role::Reconstruct );

has foo => (
    is       => 'ro',
    default  => 'foo',
    init_arg => undef,
);

package MyTest::Subclass;

use Moo;
extends qw( MyTest );
with qw( MooX::Role::Reconstruct );

has fog => (
    is       => 'ro',
    default  => 'fog',
    init_arg => undef,
);

package main;

use Test::More;

use_ok('MyTest::Subclass');

my $to2 = MyTest::Subclass->reconstruct( foo => 'baz', fog => 'baz' );
is( $to2->foo, 'baz', 'value set from reconstructor' );
is( $to2->fog, 'baz', 'value set from reconstructor' );

my $to1 =
  new_ok( 'MyTest::Subclass' => [ foo => 'baz', fog => 'baz' ], '$to1' );
is( $to1->foo, 'foo', 'default value set in constructor' );
is( $to1->fog, 'fog', 'default value set in constructor' );

done_testing();

exit;

__END__
