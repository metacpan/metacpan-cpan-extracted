use Test::More tests => 3;
use Runops::Trace 'checksum_code_path';

sub is_even { $_[0] % 2 == 0 ? 'even' : 'odd' }

my @paths;
for my $i ( 0 .. 3 ) {
    $paths[$i] = checksum_code_path( sub { is_even($i) } );
}

is( $paths[0], $paths[2] );
is( $paths[1], $paths[3] );
isnt( $paths[0], $paths[1] );
