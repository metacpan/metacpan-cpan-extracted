use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Subtest qw{subtest_streamed};
use Test2::Plugin::NoWarnings;
use Test::MockModule qw{strict};

use IO::Socket::INET;
use POSIX();
use Capture::Tiny();

use FindBin;

use lib "$FindBin::Bin/../lib";

use Net::OpenSSH::More;

# A machine that reboots takes the master with it.  The library opens a new
# master when a command finds the old one gone, and the command has to run on
# that new one, through the object that the caller holds.
subtest_streamed "a command after the master died runs on a new master, in the same object" => sub {
    local %Net::OpenSSH::More::cache;

    # Each attempt insists on a real TCP connect before it will try to
    # authenticate, so give it something listening.
    my $listener = IO::Socket::INET->new(
        'LocalAddr' => '127.0.0.1',
        'Listen'    => 5,
        'Proto'     => 'tcp',
    );
    ok( $listener, "Bound a listener for the reachability check" ) or return;

    # Each master is a generation.  A dead one fails its check and every
    # command, as a master whose far end rebooted does.
    my $generation = 0;
    my @torn_down;
    my $parent_mock = Test::MockModule->new('Net::OpenSSH');
    $parent_mock->redefine(
        'new'          => sub { $generation++; return bless { 'gen' => $generation, '_perl_pid' => $$, '_ctl_path' => "/bogus/ctl-$generation" }, $_[0]; },
        'error'        => sub { return $_[0]{'dead'} ? 'master is gone' : 0; },
        'check_master' => sub { return !$_[0]{'dead'}; },
        'open3pty'     => sub {
            my ($self) = @_;
            return if $self->{'dead'};
            my $out = "ran on $self->{'gen'}\n";
            my $err = q{};
            open( my $pty,    '<', \$out ) or die;
            open( my $stderr, '<', \$err ) or die;

            # A real child, which $send reaps.
            my $pid = fork() // die "Cannot fork: $!";
            POSIX::_exit(0) if !$pid;
            return ( $pty, $stderr, $pid );
        },
    );
    {
        # MockModule can't redefine destructors properly, as the mock goes out
        # of scope along with the thing it is mocking.
        no warnings qw{redefine};
        *Net::OpenSSH::DESTROY = sub { push( @torn_down, $_[0]{'gen'} ) if $_[0]{'gen'}; return };
    }

    my $obj = Net::OpenSSH::More->new(
        'host'                 => '127.0.0.1',
        'port'                 => $listener->sockport(),
        'password'             => 'mock',
        'retry_max'            => 2,
        'retry_interval'       => 0,
        'no_cache'             => 1,
        'use_persistent_shell' => 0,
    );
    is( $obj->{'gen'}, 1, "Connected on the first master" );

    $obj->{'dead'} = 1;
    my ( $out, undef, $code );
    Capture::Tiny::capture_merged( sub { ( $out, undef, $code ) = $obj->cmd('true') } );

    is( $code,                   0,           "The command ran" );
    is( $out,                    'ran on 2',  "on the second master" );
    is( $obj->{'gen'},           2,           "which the caller's object now holds" );
    is( $obj->{'_opts'}{'host'}, '127.0.0.1', "with the options it was made with" );
    is( \@torn_down,             [],          "and nothing tore the new master down" );
};

done_testing();
