#!perl

BEGIN {
	unshift @INC, 'blib/lib', 'blib/arch';
}

use Socket::Class;
use Time::HiRes;

$c = Socket::Class->new(
	'remote_addr' => 'localhost',
	'remote_port' => 13400,
) or die Socket::Class->error;

while( ! $c->is_error ) {
	if( $c->is_writable( 100 ) ) {
		$c->writeline( Time::HiRes::time );
		if( $c->is_readable( 100 ) ) {
			$_ = $c->readline;
			printf "ping %0.3f ms\n", (Time::HiRes::time - $_) * 1000;
			$c->wait( 100 );
		}
	}
}
