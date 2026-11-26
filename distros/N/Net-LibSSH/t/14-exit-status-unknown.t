#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;

# exit_status() answers -1 whenever there is no exit code to report. On
# libssh >= 0.11.0 the XS calls ssh_channel_get_exit_state() and maps every
# rc but SSH_OK to -1; below that it calls ssh_channel_get_exit_status(),
# which gives the same -1 on its own. Two ways to get there, and this file
# pins both, so the answer cannot drift with the libssh the build landed on:
#
#   - the process has not exited before the session timeout runs out:
#     get_exit_state() returns SSH_AGAIN, the "not yet" case of the POD;
#   - the process was killed by a signal: sshd sends exit-signal, never
#     exit-status, so get_exit_state() returns SSH_OK with the code libssh
#     initialised to (uint32_t)-1, and the int conversion has to keep that -1.
#
# -1 for "not yet" must not stick: a later call, once the process has exited,
# returns its real code. Every call runs under alarm() so a libssh build that
# blocks instead fails this file rather than hanging the suite.

my $srv = TestSSHD->start;
plan skip_all => 'sshd or ssh-keygen not available' unless $srv;

my $ssh = Net::LibSSH->new;
$ssh->option(host       => $srv->host);
$ssh->option(port       => $srv->port);
$ssh->option(user       => scalar getpwuid($<));
$ssh->option(knownhosts => $srv->known_hosts);

$ssh->connect
    or plan skip_all => 'connect failed: ' . ($ssh->error // '');
$ssh->auth_publickey($srv->client_key)
    or plan skip_all => 'auth failed: ' . ($ssh->error // '');

sub with_timeout {
    my ($seconds, $code) = @_;
    my $result;
    local $@;
    eval {
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };
        alarm($seconds);
        $result = $code->();
        alarm(0);
    };
    my $err = $@;
    alarm(0);
    return ($result, $err);
}

# killed by a signal: there is no exit code, only a signal name
{
    my $ch = $ssh->channel;
    ok $ch->exec('kill -9 $$'), 'exec() of a self-killing shell succeeds';
    is $ch->read, '', 'the killed process wrote nothing';

    my ($rc, $err) = with_timeout(10, sub { $ch->exit_status });
    is $err, '', 'exit_status() after a signal death returns within 10s';
    is $rc, -1, 'exit_status() is -1 for a process killed by a signal';

    # waiting longer does not turn it into a code
    ($rc, $err) = with_timeout(10, sub { $ch->exit_status });
    is $err, '', 'a second exit_status() after a signal death returns within 10s';
    is $rc, -1, 'exit_status() is still -1 on the second call';
    $ch->close;
}

# not exited yet: the session timeout runs out first
{
    $ssh->option(timeout => 1);
    my $ch = $ssh->channel;
    ok $ch->exec('sleep 5; exit 9'), 'exec() of a slow command succeeds';

    my ($rc, $err) = with_timeout(10, sub { $ch->exit_status });
    is $err, '', 'exit_status() gives up within 10s on a 1s session timeout';
    is $rc, -1, 'exit_status() is -1 while the remote process is still running';

    # each call waits up to the 1s timeout; the command needs about 5
    ($rc, $err) = with_timeout(20, sub {
        my $status = -1;
        for (1 .. 15) {
            $status = $ch->exit_status;
            last if $status != -1;
        }
        return $status;
    });
    is $err, '', 'asking again until the process exits returns within 20s';
    is $rc, 9, 'once the process has exited, exit_status() returns its real code';
    $ch->close;
}

done_testing;
