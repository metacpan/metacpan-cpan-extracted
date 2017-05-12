#!perl

BEGIN {
	unshift @INC, 'blib/lib', 'blib/arch';
}

use Socket::Class;

$s = Socket::Class->new(
	'local_port' => 13401,
	'listen' => 10,
	'reuseaddr' => 1,
) or die Socket::Class->error;

while( $c = $s->accept ) {
	print "connection ", $c->to_string, "\n";
	$buf = '';
	while( ! $c->is_error ) {
		if( $c->is_readable( 100 ) ) {
			$got = $c->read( $tmp, 4096 )
				or last;
			$buf .= $tmp;
		}
	}
	print "received ", length( $buf ), " bytes\n";
}
