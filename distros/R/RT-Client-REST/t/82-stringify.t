#!/usr/bin/perl
#
# This script tests whether submited data looks good

use strict;
use warnings;

use Test::More;

use Error qw(:try);
use IO::Socket;
use RT::Client::REST;

# apply the same rule as for 80-timeout.t
plan( skip_all => "LWP::UserAgent 6.04 does not know how to time out, ".
                  "see RT #81799" ) if $LWP::UserAgent::VERSION eq '6.04';


my $server = IO::Socket::INET->new(
    Type => SOCK_STREAM,
    Reuse => 1,
    Listen => 10,
) or die "Could not set up TCP server: $@";

my $port = $server->sockport;

my $pid = fork;
die "cannot fork: $!" unless defined $pid;

if (0 == $pid) {                                            # Child
    my $rt = RT::Client::REST->new(
            server => "http://localhost:$port",
            # This ensures that we die soon.  When the client dies, the
            # while (<$client>) above stops looping.
            timeout => 2,
    );
    try {
        $rt->_submit("ticket/1", "aaaa", {
                user => 'a',
                pass => 'b',
        });
    } catch RT::Client::REST::RequestTimedOutException with {
        # This is what we expect, so we ignore this exception
    };
    exit 0;
}

plan tests => 3;
my $buf;
my $client = $server->accept;
my $data;
while (<$client>) {
    $data .= $_;
}
unlike($data, qr/ARRAY\(/, "Avoid stringify objects when sending a request");
SKIP: {
    skip "Self-tests only for release testing", 2
        unless $ENV{RELEASE_TESTING};
    my $kid = waitpid $pid, 0;
    is($kid, $pid, "self-test: we reaped process correctly");
    is($?, 0, "self-test: child process ran successfully");
};

# vim:ft=perl:
