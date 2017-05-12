# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Socket::PassAccessRights;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Socket;

sub open_unix_server {
    my ($name) = @_;  # filesystem name of the socket
    #my $proto = getprotobyname('tcp');
    my $serv_params = sockaddr_un($name);
    
    if (socket (SERV_S, PF_UNIX, SOCK_STREAM, 0)) {
	unlink $name;
        warn "next bind\n" if $trace > 2;
        if (bind (SERV_S, $serv_params)) {
            #my $old_out = select (SERV_S); $| = 1; select ($old_out);
	    warn "next listen\n" if $trace > 2;
	    if (listen(SERV_S, SOMAXCONN)) {
		# Success, now we're ready to accept
		return *SERV_S{IO};
	    }
        }
    }
    warn "$0 $$: open_unix_server: failed $name ($!)\n";
    close SERV_S;
    return (); # Fail
}

sub accept_unix_connection {
    accept(CLIENT, SERV_S) or warn "accept: $!";
    return *CLIENT{IO};
}

$rendevouz = "/tmp/test-passaccessrights-$$";
open_unix_server($rendevouz) or die;

unless ($pid = fork) {
    ### Child or undef (failure, that is) comes here
    die "fork: $!" if !defined $pid;
    open F, '<test.pl' or die "open test.pl: $!";
    socket S, PF_UNIX, SOCK_STREAM, 0  or die "socket: $!";
    connect S, sockaddr_un($rendevouz) or die "connect($rendevouz): $!";
    $was = select S; $|=1; select $was;
    &Socket::PassAccessRights::sendfd(fileno(S), fileno(F))
	or die "failed to send fd: $!";
#    warn "sent\n";
    exit 0;
}
die "fork: $!" if !$pid;

$CLI = accept_unix_connection() or die;
$was = select $CLI; $|=1; select $was;

$fd = Socket::PassAccessRights::recvfd(fileno($CLI))
    or die "failed to receive fd: $!";

open PASS, "<&=$fd" or die "open received fd $fd failed: $!";
$x = <PASS>;
print $x =~ /\# Before/ ? "ok 2\n" : "not ok 2\n";

#EOF
