use Test::More 0.98;

my $class = 'Net::MAC::Vendor';

use_ok( $class );
ok( defined &{"${class}::run"}, "run() method is defined" );
can_ok( $class, qw(run) );

{
local *STDOUT;

open STDOUT, ">", \ my $output;

my $rc = $class->run( '00:0d:93:84:49:ee' );

SKIP: {
	skip 'Problem looking up data', 1 unless defined $rc;
	like( $output, qr/Apple/, 'OUI belongs to Apple');
	}
}

done_testing();
