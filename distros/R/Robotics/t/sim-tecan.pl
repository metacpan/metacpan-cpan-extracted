#!/usr/bin/perl -w
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
package SimulateTecan;


my $Tecan_pipename="/tmp/gemini";	# for Test
my %Responses = (
	'default',		'0;OK',
	'default_e',	'3;error',
	'version', 		'0;Version 4.1.0.0',
	'version_e',	'3;error',
	'status',		'0;IDLE',
	'status_e',		'3;BUSY'
);
my $pid;
my $stop = 1;

&Start;
return 1;

sub Start {
	# Verify if this works on Win32, I bet not 
	use POSIX qw(mkfifo);
	unlink($Tecan_pipename);  # XXX: Watch out
    mkfifo($Tecan_pipename, 0700) or die "mkfifo $Tecan_pipename failed: $!";
	warn "\n!! SimulateTecan Starting on $Tecan_pipename\n";
	$pid = fork();
	if ($pid) {
		exit(0);
	}
    $stop = 0;
	&Thread;
}
sub Thread {
	use IO::Handle;
    use Fcntl;
	sysopen(PIPE, $Tecan_pipename, O_RDWR) || die "sysopen fail $Tecan_pipename";
	$SIG{CHLD} = 'IGNORE';
	$SIG{PIPE} = 'IGNORE';
	warn "\n# !! SimulateTecan Thread is running on $Tecan_pipename\n";
	my $response;
	while ($_ = <PIPE>) {
        s/[\0\n\r\t]//go;
		warn "\n# !! Simulator got '$_'\n";
		$response = Reply($_, 0);
		print PIPE "$response\0";
		warn "\n# !! Simulator got '$_', sent '$response'\n";
		last if $stop;
	}
	warn "\n# !! SimulateTecan Stopped.\n";
	close(PIPE);
	unlink($Tecan_pipename);
	exit(0);
}

sub Reply { 
	my ($cmd, $doerr) = ($_[0], $_[1]);
	my $reply;
	my $err;
	$cmd =~ tr/A-Z/a-z/;
	$reply = $Responses{$cmd};
	$err = $Responses{$cmd};
	if (!$reply) {
		$reply = $err;
	}
	if ($doerr > 0) {
		# force error response in order to test
		$reply = $err;
	}
	if (!$reply && !$err) {
		$reply = $Responses{"default_e"};
	}
	return $reply;
}

sub Shutdown {
	$stop = 1;
}
__DATA__
__END__
