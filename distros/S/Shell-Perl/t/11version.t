
use Test::More tests => 8;

my @pirl = ( $^X, '-Mblib', 'blib/script/pirl' );

use IPC::Cmd qw( run );
use Test::Deep;

for my $switch ( '-v', '--version' ) {
    my ( $ok, $err, $full_buf, $out_buf, $err_buf )  = run( command => [ @pirl, $switch ] );
    ok( $ok, "'pirl $switch' run ok" );
    ok( !$err, 'no error');
    cmp_deeply( $out_buf, [ re(qr/\AThis is pirl/) ], 'printed version info' );
    my $NO_STDERR_OUTPUT = ($] < 5.008)
      ? [re(qr/Using .* lib \n/msx)]   # cope with noisy 5.6 blib
      : [];
    cmp_deeply( $err_buf, $NO_STDERR_OUTPUT, 'no output to STDERR' )
      or diag("err_buf= (@$err_buf)");
}
