use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Tools::Subtest qw{subtest_streamed};
use Test2::Plugin::NoWarnings;
use Test::MockModule qw{strict};

use IO::Socket::INET;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Net::OpenSSH::More;

# A connection that comes back with an error is taken by a `next` inside the
# retry loop, so anything sitting at the foot of that loop never runs for it.
# retry_interval was applied down there, which left every attempt running back
# to back against a host that was refusing them.
subtest_streamed "retry_interval is waited out between attempts" => sub {
    local %Net::OpenSSH::More::cache;
    local $Net::OpenSSH::More::disable_destructor = 1;

    # Each attempt insists on a real TCP connect before it will try to
    # authenticate, and the thing that does it is a lexical closure with no way
    # in. Give it something genuinely listening rather than resting on whether
    # this machine happens to run sshd.
    my $listener = IO::Socket::INET->new(
        'LocalAddr' => '127.0.0.1',
        'Listen'    => 5,
        'Proto'     => 'tcp',
    );
    ok( $listener, "Bound a listener for the reachability check" ) or return;

    my $attempts    = 0;
    my $parent_mock = Test::MockModule->new('Net::OpenSSH');
    $parent_mock->redefine(
        'new' => sub { $attempts++; return bless {}, $_[0]; },

        # Deliberately not a refused credential. Those are not retried at all
        # unless retry_on_auth_failure asks for it, and what is under test here
        # is the interval between attempts rather than which failures earn one.
        'error'        => sub { return $attempts <= 2 ? 'master would not come up' : 0; },
        'check_master' => sub { return $attempts > 2; },
    );
    {
        # MockModule can't redefine destructors properly, as the mock goes out
        # of scope along with the thing it is mocking.
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { undef };
    }

    my $start = time;
    my $obj   = Net::OpenSSH::More->new(
        'host'           => '127.0.0.1',
        'port'           => $listener->sockport(),
        'password'       => 'mock',
        'retry_max'      => 5,
        'retry_interval' => 1,
        'no_cache'       => 1,
    );
    my $elapsed = time - $start;

    is( ref $obj,  'Net::OpenSSH::More', "Retried a rejected connection rather than burning every attempt at once" );
    is( $attempts, 3,                    "Connected on the third attempt" );

    # Two retries at a second each.  Before the fix this came back instantly,
    # so the assertion that matters is that any waiting happened at all.
    ok( $elapsed >= 2, "Waited retry_interval between attempts (${elapsed}s across two retries)" );
};

done_testing();
