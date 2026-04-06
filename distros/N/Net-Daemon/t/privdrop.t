#!/usr/bin/perl
#
# Test that Bind() drops privileges permanently.
#
# Two concerns:
#   1. Silent failure: Perl's $> = $uid silently ignores setuid failures.
#      Bind() must detect and abort on failed privilege changes.
#   2. Saved-set-user-ID: Using $< = ($> = $uid) leaves saved-set-user-ID
#      as root, allowing the process to regain root via $> = 0.
#      Bind() must use POSIX::setuid() to set all three UIDs.
#

use strict;
use warnings;
use Test::More;
use IO::Socket ();

if ($^O eq 'MSWin32') {
    plan skip_all => 'Privilege dropping is not applicable on Windows';
}

plan tests => 3;

use_ok('Net::Daemon');

# Override Fatal to capture calls instead of dying
my @fatals;
{
    no warnings 'redefine', 'prototype', 'once';
    *Net::Daemon::Log::Fatal = sub ($$;@) {
        my ($self, $fmt, @args) = @_;
        push @fatals, sprintf($fmt, @args);
        die "Fatal called\n";
    };
}

# --- Test: non-root UID change must fail with Fatal ---
SKIP: {
    skip 'Cannot test privilege drop failure when running as root', 1
        if $> == 0;

    @fatals = ();
    my $bogus_uid = ($> == 65534) ? 65533 : 65534;
    my $self = bless {
        'user'     => $bogus_uid,
        'pidfile'  => 'none',
        'mode'     => 'single',
        'catchint' => 1,
        'done'     => 1,
        'socket'   => IO::Socket::INET->new(
            'LocalAddr' => '127.0.0.1',
            'LocalPort' => 0,
            'Proto'     => 'tcp',
            'Listen'    => 1,
            'Reuse'     => 1,
        ),
    }, 'Net::Daemon';

    local $SIG{ALRM} = sub { die "Timed out\n" };
    alarm(5);
    eval { $self->Bind() };
    alarm(0);

    my $got_uid_fatal = scalar(@fatals) && grep { /UID|uid|setuid|Failed/i } @fatals;
    ok($got_uid_fatal, 'Bind() detects failed UID change and calls Fatal()')
        or diag("Got: ", @fatals ? join('; ', @fatals) : '(no Fatal)');
}

# --- Test: saved-set-user-ID is dropped (root + Linux only) ---
SKIP: {
    skip 'Requires root on Linux to test saved-set-user-ID', 1
        unless $> == 0 && $^O eq 'linux' && -r '/proc/self/status';

    # Drop to nobody (65534) and verify saved-set-user-ID
    my $target_uid = 65534;
    @fatals = ();
    my $self = bless {
        'user'     => $target_uid,
        'pidfile'  => 'none',
        'mode'     => 'single',
        'catchint' => 1,
        'done'     => 1,
        'socket'   => IO::Socket::INET->new(
            'LocalAddr' => '127.0.0.1',
            'LocalPort' => 0,
            'Proto'     => 'tcp',
            'Listen'    => 1,
            'Reuse'     => 1,
        ),
    }, 'Net::Daemon';

    local $SIG{ALRM} = sub { die "Timed out\n" };
    alarm(5);
    eval { $self->Bind() };
    alarm(0);

    # Read saved-set-user-ID from /proc/self/status
    my $saved_uid;
    if (open my $fh, '<', '/proc/self/status') {
        while (<$fh>) {
            if (/^Uid:\s+\d+\s+\d+\s+(\d+)/) {
                $saved_uid = $1;
                last;
            }
        }
        close $fh;
    }

    is($saved_uid, $target_uid,
        'saved-set-user-ID is dropped (not left as root)')
        or diag("saved-set-user-ID=$saved_uid, expected $target_uid");
}
