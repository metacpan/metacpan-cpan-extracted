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

# Each attempt insists on a real TCP connect before it will try to
# authenticate, and the thing that does it is a lexical closure with no way in.
# Give it something genuinely listening rather than resting on whether this
# machine happens to run sshd.
# Nothing ever accepts these, so the backlog has to be deeper than the number
# of attempts both subtests make between them. Fill it and the connects stall
# on retransmit rather than failing, which turns a second of testing into two
# minutes of it.
my $listener = IO::Socket::INET->new(
    'LocalAddr' => '127.0.0.1',
    'Listen'    => 50,
    'Proto'     => 'tcp',
);

# A parent that refuses every attempt, writing the refusal where a real ssh
# master would write it. syswrite because the module asks the file how big it
# is before reading it, and buffered output is not there to be measured yet.
sub refusing_mock {
    my ($counter) = @_;
    my $mock = Test::MockModule->new('Net::OpenSSH');
    $mock->redefine(
        'new' => sub {
            my ( $class, %args ) = @_;
            ${$counter}++;
            syswrite( $args{'master_stderr_fh'}, "doge\@127.0.0.1: Permission denied (publickey)." ) if $args{'master_stderr_fh'};
            return bless {}, $class;
        },
        'error'        => sub { return 'master would not come up'; },
        'check_master' => sub { return 0; },
    );
    return $mock;
}

subtest_streamed "a refused credential is not retried by default" => sub {
    plan 'skip_all' => 'could not bind a listener' if !$listener;
    local %Net::OpenSSH::More::cache;
    local $Net::OpenSSH::More::disable_destructor = 1;

    my $attempts = 0;
    my $mock     = refusing_mock( \$attempts );

    my $died = dies {
        Net::OpenSSH::More->new(
            'host'      => '127.0.0.1',
            'port'      => $listener->sockport(),
            'password'  => 'mock',
            'retry_max' => 5,
            'no_cache'  => 1,
        );
    };

    like( $died, qr/Bad credentials, will not retry/, "Gave up naming the credential as the reason" );
    is( $attempts, 1, "Stopped after the first refusal rather than spending all five attempts" );
};

subtest_streamed "retry_on_auth_failure spends the attempts instead" => sub {
    plan 'skip_all' => 'could not bind a listener' if !$listener;
    local %Net::OpenSSH::More::cache;
    local $Net::OpenSSH::More::disable_destructor = 1;

    my $attempts = 0;
    my $mock     = refusing_mock( \$attempts );

    my $died = dies {
        Net::OpenSSH::More->new(
            'host'                  => '127.0.0.1',
            'port'                  => $listener->sockport(),
            'password'              => 'mock',
            'retry_max'             => 3,
            'retry_interval'        => 0,
            'retry_on_auth_failure' => 1,
            'no_cache'              => 1,
        );
    };

    like( $died, qr/Failed to establish SSH connection after 3 attempts/, "Ran out of attempts rather than refusing to make them" );
    is( $attempts, 3, "Made all three attempts" );
};

done_testing();
