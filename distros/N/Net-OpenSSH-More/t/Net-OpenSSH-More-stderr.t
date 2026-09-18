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

# The handle opened to catch the ssh master's stderr is handed down by name,
# and the name was spelled master_sdterr_fh in the list of things forwarded to
# the parent. Nothing else spells it that way, so it was dropped on the way
# past: everything the master said went to the caller's own stderr instead, and
# the file it was supposed to land in stayed empty.
subtest_streamed "the master's stderr handle is forwarded to Net::OpenSSH" => sub {
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

    my %got;
    my $parent_mock = Test::MockModule->new('Net::OpenSSH');
    $parent_mock->redefine(
        'new'          => sub { my ( $class, %args ) = @_; %got = %args; return bless {}, $class; },
        'error'        => sub { return 0; },
        'check_master' => sub { return 1; },
    );
    {
        # MockModule can't redefine destructors properly, as the mock goes out
        # of scope along with the thing it is mocking.
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { undef };
    }

    my $obj = Net::OpenSSH::More->new(
        'host'      => '127.0.0.1',
        'port'      => $listener->sockport(),
        'password'  => 'mock',
        'retry_max' => 1,
        'no_cache'  => 1,
    );

    is( ref $obj, 'Net::OpenSSH::More', "Built an object to go with the connection" );
    ok( $got{'master_stderr_fh'}, "master_stderr_fh reached Net::OpenSSH rather than being dropped" );
};

done_testing();
