#!perl

print "1..$_tests\n";

require Socket::Class::SSL;

if( $^O eq 'cygwin' ) {
	_skip_all();
}

#$ctx = Socket::Class::SSL::CTX->new();

$s = Socket::Class::SSL->new(
	'certificate' => 'cert/server.crt',
	'private_key' => 'cert/server.key',
	'local_addr' => '127.0.0.1',
	'listen' => 10,
	'reuseaddr' => 1,
) or die Socket::Class->error();

my $pid = fork();
if( not defined $pid ) {
	#print "resources not avilable.\n";
	_skip_all();
}
elsif( $pid == 0 ) {
	#print "IM THE CHILD\n";
	$c = Socket::Class::SSL->new(
		'remote_addr' => '127.0.0.1',
		'remote_port' => $s->local_port,
	) or exit();
	$c->say( "hello server" ) or exit();
	$c->is_readable( 100 ) or exit();
	$l = $c->readline or exit();
	exit(0);
}
else {
	#print "IM THE PARENT\n";
	_check( $c = $s->accept ) or _fail_all();
	_check( $c->is_readable( 100 ) ) or _fail_all();
	_check( $l = $c->readline ) or _fail_all();
	_check( $l eq "hello server" ) or _fail_all();
	_check( $c->say( "hello client" ) ) or _fail_all();
	waitpid( $pid, 0 );
}

BEGIN {
	$_tests = 5;
	$_pos = 1;
	unshift @INC, 'blib/lib', 'blib/arch';
}

sub _check {
	print "" . ($_[0] ? "ok" : "not ok") . " $_pos\n";
	$_pos ++;
	return $_[0];
}

sub _skip_all {
	print STDERR "Skipped: probably not supported on this platform\n";
	for( ; $_pos <= $_tests; $_pos ++ ) {
		print "ok $_pos\n";
	}
	exit;
}

sub _fail_all {
	for( ; $_pos <= $_tests; $_pos ++ ) {
		print "not ok $_pos\n";
	}
	exit;
}
