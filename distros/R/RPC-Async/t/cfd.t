use strict;
use warnings;

use Test::More tests => 10;
use RPC::Async::Client;
use IO::EventMux;
use RPC::Async::URL;
use English;

my $mux = IO::EventMux->new();

# Set the user for the server to run under.
$ENV{'IO_URL_USER'} ||= 'root';

my $rpc = RPC::Async::Client->new($mux, "perl://./test-server.pl") or die;

$rpc->no_such_method(0, sub {
    my (%ans) = @_;
    ok(defined $ans{errors}, "Invalid method call gives error");
});

sub test_add {
    my ($n1, $n2) = @_;
    $rpc->add_numbers(n1 => $n1, n2 => $n2,
        sub {
            my %reply = @_;
            print "$0: $n1 + $n2 = $reply{sum}\n";
            is($n1 + $n2, $reply{sum}, "Addition of $n1 and $n2");
        });
}

test_add(3, 4);
test_add(-2, 2);

sub test_get_id {
    $rpc->get_id(
        sub {
            my %reply = @_;
            print "$0: uid:$reply{uid}, gid:$reply{gid}".
	    	    ", euid:$reply{euid}, egid:$reply{egid}\n";
            
            # Find the right uid and gid to compare with.
            my ($uid, $gid) = (getpwnam($ENV{SUDO_USER} || '') 
                || getpwnam($ENV{'IO_URL_USER'} || '') 
                || getpwnam($ENV{LOGNAME1} || '')
            )[2,3] || ($UID, (split(/ /,$GID))[0]);

            $gid = "$gid $gid";
            
            # Support running as a normal user.
            if($UID != 0 and $EUID != 0 
                and $GID != 0 and $EGID != 0) {
                $uid=$UID;
                $gid=$GID;
            }
                
            is($uid, $reply{uid}, "Check uid");
            is($gid, $reply{gid}, "Check gid");
            is($uid, $reply{euid}, "Check euid");
            is($gid, $reply{egid}, "Check egid");
        });
}

test_get_id();

my $callback_counter = 0;
sub callback {
    my ($calls) = @_;
    $callback_counter++;
    is($calls, 2, "callback: count = $callback_counter");
}

# This test should be the last one to test whether has_coderefs works
$rpc->callback(calls => 2,
    callback => { key => [ \( \&callback ) ] }, sub {
        ok(1, "callback: returned");
    });

while ($rpc->has_requests || $rpc->has_coderefs) {
    my $event = $mux->mux;
    $rpc->io($event);
}

$rpc->disconnect;
