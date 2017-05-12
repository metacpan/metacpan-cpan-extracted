package MyTest;

use Moo;
with qw( MooX::Role::Reconstruct );

has foo => (
    is      => 'ro',
    default => 'foo',
);

package MyTest::Subclass;
use Moo;
with qw( MooX::Role::Reconstruct );
extends qw( MyTest );

has bar => (
    is      => 'ro',
    default => 'bar',
);

package main;

$| = 1;

use Test::More;

use_ok('MyTest::Subclass');
can_ok( 'MyTest::Subclass', 'reconstruct' );

my $to = MyTest::Subclass->reconstruct( foo => 'baz', bar => 'baz' );
isa_ok( $to, 'MyTest::Subclass', 'reconstructed object' );
isa_ok( $to, 'MyTest',           'reconstructed object' );
is( $to->foo, 'baz', 'foo value set from reconstruct' );
is( $to->bar, 'baz', 'bar value set from reconstruct' );

done_testing();

exit;

__END__
