#!perl

BEGIN {
	unshift @INC, 'blib/lib', 'blib/arch';
}

use Socket::Class;

$s = Socket::Class->new(
	'local_port' => 13400,
	'listen' => 10,
	'reuseaddr' => 1,
) or die Socket::Class->error;

while( $c = $s->accept ) {
	print "connection ", $c->to_string, "\n";
	while( ! $c->is_error ) {
		if( $c->is_readable( 100 ) ) {
			$_ = $c->readline;
			if( $c->is_writable( 100 ) ) {
				$c->writeline( $_ );
			}
		}
	}
}
