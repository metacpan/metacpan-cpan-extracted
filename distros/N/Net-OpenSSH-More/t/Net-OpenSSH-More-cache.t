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

# Nothing ever accepts these, so the backlog has to outlast every attempt the
# subtests make between them, or the connects stall on retransmit instead of
# failing.
my $listener = IO::Socket::INET->new(
    'LocalAddr' => '127.0.0.1',
    'Listen'    => 50,
    'Proto'     => 'tcp',
);

# The cache is indexed on the three things that identify a connection, and the
# user is whoever is running this.
sub cache_key {
    my ($port) = @_;
    my $user = $ENV{'USER'} || getpwuid($>);
    return "${user}_127.0.0.1_${port}";
}

subtest_streamed "a cached object that still answers is handed back" => sub {
    plan 'skip_all' => 'could not bind a listener' if !$listener;
    local %Net::OpenSSH::More::cache;
    local $Net::OpenSSH::More::disable_destructor = 1;

    my $port = $listener->sockport();

    # Building a connection publishes its socket into the environment now, so
    # keep this subtest's changes to itself.
    local %ENV = %ENV;

    my $built = 0;
    my $mock  = Test::MockModule->new('Net::OpenSSH');
    $mock->redefine(
        'new'           => sub { $built++; return bless {}, $_[0]; },
        'error'         => sub { return 0; },
        'check_master'  => sub { return 1; },
        'test'          => sub { return 1; },
        'disown_master' => sub { return 4242; },
        'get_ctl_path'  => sub { return '/tmp/bogus-ctl-path-for-testing'; },
    );
    {
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { undef };
    }

    my $cached = bless {}, 'Net::OpenSSH::More';
    $Net::OpenSSH::More::cache{ cache_key($port) } = $cached;

    my $got = Net::OpenSSH::More->new(
        'host'     => '127.0.0.1',
        'port'     => $port,
        'password' => 'mock',
    );

    is( $got,   exact_ref($cached), "Got the cached object rather than a new one" );
    is( $built, 0,                  "Did not open a second connection" );
};

subtest_streamed "a cached object whose far end has gone is not" => sub {
    plan 'skip_all' => 'could not bind a listener' if !$listener;
    local %Net::OpenSSH::More::cache;
    local $Net::OpenSSH::More::disable_destructor = 1;

    my $port = $listener->sockport();

    # Building a connection publishes its socket into the environment now, so
    # keep this subtest's changes to itself.
    local %ENV = %ENV;

    my $built = 0;
    my $mock  = Test::MockModule->new('Net::OpenSSH');
    $mock->redefine(
        'new'           => sub { $built++; return bless {}, $_[0]; },
        'error'         => sub { return 0; },
        'check_master'  => sub { return 1; },
        'disown_master' => sub { return 4242; },
        'get_ctl_path'  => sub { return '/tmp/bogus-ctl-path-for-testing'; },

        # The local master is fine and the far end is gone, which is the whole
        # point: check_master cannot tell these two apart. A bare return is
        # undef in the scalar context it is asked in, which is what
        # Net::OpenSSH::test answers with when the connection is the problem.
        'test' => sub { return; },
    );
    {
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { undef };
    }

    my $cached = bless {}, 'Net::OpenSSH::More';
    $Net::OpenSSH::More::cache{ cache_key($port) } = $cached;

    my $got = Net::OpenSSH::More->new(
        'host'     => '127.0.0.1',
        'port'     => $port,
        'password' => 'mock',
    );

    isnt( $got, exact_ref($cached), "Refused the cached object whose far end stopped answering" );
    is( $built, 1, "Opened a fresh connection instead" );
};

subtest_streamed "the master's socket is published for children to reuse" => sub {
    plan 'skip_all' => 'could not bind a listener' if !$listener;
    local %Net::OpenSSH::More::cache;
    local $Net::OpenSSH::More::disable_destructor = 1;

    my $port = $listener->sockport();
    my $user = $ENV{'USER'} || getpwuid($>);
    my $key  = "NET_OPENSSH_MASTER_127_0_0_1_${user}";
    local $ENV{$key};
    delete $ENV{$key};

    my $mock = Test::MockModule->new('Net::OpenSSH');
    $mock->redefine(
        'new'           => sub { return bless {}, $_[0]; },
        'error'         => sub { return 0; },
        'check_master'  => sub { return 1; },
        'test'          => sub { return 1; },
        'disown_master' => sub { return 4242; },
        'get_ctl_path'  => sub { return '/tmp/bogus-ctl-path-for-testing'; },
    );
    {
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { undef };
    }

    my $got = Net::OpenSSH::More->new(
        'host'     => '127.0.0.1',
        'port'     => $port,
        'password' => 'mock',
    );

    is( $ENV{$key},           '/tmp/bogus-ctl-path-for-testing', "Published the control socket into the environment" );
    is( $got->{'master_pid'}, 4242,                              "Kept the disowned master's pid" );
    is( $got->{'host_sock'},  '/tmp/bogus-ctl-path-for-testing', "Recorded the socket on the object" );
};

done_testing();
