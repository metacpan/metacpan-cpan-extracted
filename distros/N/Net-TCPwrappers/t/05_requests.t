#
# $Id: 05_requests.t 161 2004-12-31 04:00:52Z james $
#

# Tests creating and updating request structures with both valid and bogus 
# information. Does not actually check access though.
#
# 04-Nov-2002, George A. Theall

use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 38;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

use Net::TCPwrappers qw| /^RQ_/ request_init request_set|;

###########################################################################
# Make sure Socket extension is available -- it almost certainly is.
my $socket_available;
BEGIN {
    our %Config;
    require Config; import Config;
    if ($Config{'extensions'} =~ /\bSocket\b/) {
        use Socket;
        $socket_available = 1;
    }
}



###########################################################################
# Test each key with both valid and invalid values.
my %key_tests = (
    RQ_CLIENT_ADDR      => {
            key     => RQ_CLIENT_ADDR,
            valid   => "127.0.0.1",
            invalid => 1,
    },
    RQ_CLIENT_NAME      => {
            key     => RQ_CLIENT_NAME,
            valid   => "localhost",
            invalid => 1,
    },
    RQ_CLIENT_SIN       => {
            key     => RQ_CLIENT_SIN,
            valid   => (
                        $socket_available ? 
                            scalar(sockaddr_in(1234, inet_aton("127.0.0.1"))) :
                            ""      # nb: anything's ok -- tests are skipped.
                       ),
            invalid => 1,
    },
    RQ_DAEMON           => {
            key     => RQ_DAEMON,
            valid   => "sshd",
            invalid => 22,
    },
    RQ_FILE             => {
            key     => RQ_FILE,
            valid   => fileno(STDOUT),
            invalid => "invalid",
    },
    RQ_SERVER_ADDR      => {
            key     => RQ_SERVER_ADDR,
            valid   => "127.0.0.1",
            invalid => 987,
    },
    RQ_SERVER_NAME      => {
            key     => RQ_SERVER_NAME,
            valid   => "localhost",
            invalid => 0.5,
    },
    RQ_SERVER_SIN       => {
            key     => RQ_SERVER_SIN,
            valid   => (
                        $socket_available ? 
                            scalar(sockaddr_in(1234, inet_aton("127.0.0.1"))) :
                            ""      # nb: anything's ok -- tests are skipped.
                       ),
            invalid => 0,
    },
    RQ_USER             => {
            key     => RQ_USER,
            valid   => "george",
            invalid => 3.14159265358979,
    },
);
foreach my $test (sort keys %key_tests) {
    SKIP: {
        skip("Can't test $test - Socket extension is not installed!", 4)
            if ($test =~ /_SIN$/i and !$socket_available);

        my $key = $key_tests{$test}{key};
        my $valid = $key_tests{$test}{valid};
        my $invalid = $key_tests{$test}{invalid};

        # Create request with valid value.
        my $req_valid = request_init($key, $valid);
        ok($req_valid, "request_init - $test");

        # Create request with invalid value.
        my $req_invalid = request_init($key, $invalid);
        ok(!$req_invalid, "request_init - $test w/ bogus value");

        SKIP: {
            skip("Can't call request_set for test $test  - request_init failed!", 2)
                if (!$req_valid);

            # Update request with valid value.
            $req_valid = request_set($req_valid, $key, $valid);
            ok($req_valid, "request_set - $test");

            # Update request with invalid value.
            $req_valid = request_set($req_valid, $key, $invalid);
            ok(!$req_valid, "request_set - $test w/ bogus value");
        }
    }
}


###########################################################################
# Test use of a bogus key.
no strict 'subs';
my $req = request_init(RQ_BOGUS, "bogus value");
ok(!$req, 'request_init - bogus key');
undef $req;

$req = request_init(RQ_DAEMON, "sshd");
$req = request_set($req, RQ_BOGUS, "bogus value");
ok(!$req, 'request_set - bogus key');
undef $req;

#
# EOF
