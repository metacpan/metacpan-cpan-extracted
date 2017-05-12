print "1..$_tests\n";

require Socket::Class::SSL;
_check( 1 );

BEGIN {
	$_tests = 1;
	$_pos = 1;
	unshift @INC, 'blib/lib', 'blib/arch';
}

1;

sub _check {
	my( $val ) = @_;
	print "" . ($val ? "ok" : "not ok") . " $_pos\n";
	$_pos ++;
}
