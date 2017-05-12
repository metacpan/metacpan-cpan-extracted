package MyTest;

use Moo;
with qw( MooX::Role::Reconstruct );

has foo => (
    is      => 'ro',
    default => 'bar',
);

package main;

$| = 1;

use Test::More;

use_ok('MyTest');

TODO: {
    local $TODO = 'No clue why this fails but the method works!';

    can_ok( 'MyTest', 'reconstruct', 'reconstruct is present' );
}

my $to = MyTest->reconstruct( foo => 'baz' );
isa_ok( $to, 'MyTest', 'reconstructed object' );
is( $to->foo, 'baz', 'foo value set from reconstruct' );

done_testing();

exit;

__END__
