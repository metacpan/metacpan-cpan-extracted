package MyTest;

use Moo;
with qw( MooX::Role::Reconstruct );

has foo => (
    is       => 'ro',
    default  => 'bar',
    init_arg => undef,
);

package main;

use Test::More;

use_ok('MyTest');

my $to2 = MyTest->reconstruct( foo => 'baz' );
is( $to2->foo, 'baz', 'value set from reconstructor' );

my $to1 = new_ok( MyTest => [ foo => 'baz' ], '$to1' );
is( $to1->foo, 'bar', 'default value set in constructor' );

done_testing();

exit;

__END__
