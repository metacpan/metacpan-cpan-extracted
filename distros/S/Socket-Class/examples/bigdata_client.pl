#!perl

BEGIN {
	unshift @INC, 'blib/lib', 'blib/arch';
}

use Socket::Class;

$c = Socket::Class->new(
	'remote_addr' => 'localhost',
	'remote_port' => 13401,
) or die Socket::Class->error;

$data = '#' x 3000000;
$start = 0;
$size = length( $data );
print "sending $size bytes\n"; 
while( ! $c->is_error && $start < $size ) {
	if( $c->is_writable( 100 ) ) {
		$start += $c->write( $data, $start );
	}
}
