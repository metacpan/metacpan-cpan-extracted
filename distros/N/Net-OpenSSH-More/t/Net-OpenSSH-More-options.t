use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Subtest qw{subtest_streamed};
use Test2::Plugin::NoWarnings;
use Test::MockModule qw{strict};

use IO::Socket::INET;

use FindBin;

use lib "$FindBin::Bin/../lib";

use Net::OpenSSH::More;

# Net::OpenSSH::More makes the control directory in TMPDIR and turns off
# strict_mode, because TMPDIR can have a parent that the group may write.
# Net::OpenSSH then refuses the directory unless strict_mode reaches it.
subtest_streamed "an option of 0 reaches Net::OpenSSH" => sub {
    local %Net::OpenSSH::More::cache;
    local $Net::OpenSSH::More::disable_destructor = 1;

    # The reachability check makes a real TCP connection first.
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
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { undef };
    }

    my $obj = Net::OpenSSH::More->new(
        'host'       => '127.0.0.1',
        'port'       => $listener->sockport(),
        'password'   => 'mock',
        'batch_mode' => 0,
        'timeout'    => 0,
        'retry_max'  => 1,
        'no_cache'   => 1,
    );

    is( ref $obj, 'Net::OpenSSH::More', "Connected" );
    is( $got{'strict_mode'}, 0, "strict_mode => 0 reaches Net::OpenSSH, so a control directory under a parent that the group may write is accepted" );
    is( [ @got{qw{batch_mode timeout}} ], [ 0, 0 ], "and so does an option of 0 that the caller passed" );
    ok( !exists $got{'gateway'}, "but an option that nobody set is not passed, so the default of Net::OpenSSH applies" );
};

# Net::OpenSSH names a control socket with 32 hex digits, and a socket path
# holds 108 bytes on Linux, so a TMPDIR a few directories deep ran out.
subtest_streamed "each attempt gets a short control socket of its own" => sub {
    local %Net::OpenSSH::More::cache;
    local $Net::OpenSSH::More::disable_destructor = 1;

    my $listener = IO::Socket::INET->new(
        'LocalAddr' => '127.0.0.1',
        'Listen'    => 5,
        'Proto'     => 'tcp',
    );
    ok( $listener, "Bound a listener for the reachability check" ) or return;

    my @got;
    my $parent_mock = Test::MockModule->new('Net::OpenSSH');
    $parent_mock->redefine(
        'new'          => sub { my ( $class, %args ) = @_; push @got, \%args; return bless {}, $class; },
        'error'        => sub { return @got < 2 ? 'master would not come up' : 0; },
        'check_master' => sub { return 1; },
    );
    {
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { undef };
    }

    my $obj = Net::OpenSSH::More->new(
        'host'      => '127.0.0.1',
        'port'      => $listener->sockport(),
        'password'  => 'mock',
        'retry_max' => 2,
        'no_cache'  => 1,
    );

    is( ref $obj,    'Net::OpenSSH::More', "Connected on the second attempt" );
    is( scalar @got, 2,                    "after two attempts" );
    my @paths = map { $_->{'ctl_path'} } @got;
    my $dir   = $paths[0] =~ s{/[^/]+\z}{}r;
    is( \@paths, [ "$dir/1", "$dir/2" ], "each attempt names its socket by its number, in the one directory of the object" );
    ok( !exists $got[0]{'ctl_dir'}, "and leaves Net::OpenSSH no directory to pick a long name in" );
};

done_testing();
