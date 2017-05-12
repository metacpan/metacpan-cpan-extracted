print "1..$_tests\n";

require Socket::Class;
import Socket::Class qw(:all);

$sock = Socket::Class->new()
	or warn Socket::Class->error;
_check( $sock );

if( $sock ) {
	$r = $sock->bind( '127.0.0.1', 0 )
		or warn "Error: " . $sock->error;
	_check( $r );
	$r = $sock->listen()
		or warn "Error: " . $sock->error;
	_check( $r );
	$r = $sock->close()
		or warn "Error: " . $sock->error;
	_check( $r );
	$r = $sock->set_timeout( 1000 );
	_check( $r );
	$r = $sock->connect( '10.10.10.10', 80 );
	_check( $r ? 1 : $sock->errno() );
	$r = $sock->free();
	_check( $r );
	$r = $sock->free();
	_check( ! $r );
}
else {
	_fail_all();
}

BEGIN {
	$_tests = 8;
	$_pos = 1;
	unshift @INC, 'blib/lib', 'blib/arch';
}

1;

sub _check {
	my( $val ) = @_;
	print "" . ($val ? "ok" : "not ok") . " $_pos\n";
	$_pos ++;
}

sub _skip_all {
	print STDERR "Skipped: various reasons\n";
	for( ; $_pos <= $_tests; $_pos ++ ) {
		print "ok $_pos\n";
	}
}

sub _fail_all {
	for( ; $_pos <= $_tests; $_pos ++ ) {
		print "not ok $_pos\n";
	}
}
