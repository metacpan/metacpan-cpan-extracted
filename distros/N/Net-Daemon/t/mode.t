# -*- perl -*-
#
# Test mode auto-detection and explicit mode selection

use strict;
use warnings;
use Test::More;
use Config;

use Net::Daemon ();

# Auto-detection should pick a valid mode
my $daemon = Net::Daemon->new(
    {
        'localport' => 0,
        'proto'     => 'tcp',
    },
    []
);

my $mode = $daemon->{'mode'};
ok( defined $mode, 'auto-detected mode is defined' );
like( $mode, qr/^(?:single|fork|ithreads)$/,
    "auto-detected mode '$mode' is a valid value" );

# On Perl < 5.10, auto-detection should NOT pick ithreads even if
# the interpreter was built with useithreads.  The threads::shared
# infrastructure (RegExpLock sharing) requires 5.10+, so defaulting
# to ithreads on older perls would run without thread-safe regex
# locking.
SKIP: {
    skip 'Only verifiable on Perl < 5.10', 1 if $^V ge v5.10.0;
    isnt( $mode, 'ithreads',
        'auto-detection avoids ithreads on Perl < 5.10' );
}

# On Windows, auto-detection should NOT pick ithreads.  Perl ithreads
# use DuplicateHandle() to clone socket FDs into new threads, but
# MSDN requires WSADuplicateSocket() for Winsock sockets.  The
# DuplicateHandle'd client sockets become corrupted, causing EINVAL
# on read after ~15 iterations.  See #19, #30.
SKIP: {
    skip 'Only verifiable on MSWin32', 1 unless $^O eq 'MSWin32';
    isnt( $mode, 'ithreads',
        'auto-detection avoids ithreads on Windows' );
}

# Explicit --mode=ithreads is always respected (user's choice)
SKIP: {
    skip 'No ithreads support', 1 unless $Config{useithreads};
    my $explicit = Net::Daemon->new(
        {
            'localport' => 0,
            'proto'     => 'tcp',
        },
        ['--mode=ithreads']
    );
    is( $explicit->{'mode'}, 'ithreads',
        'explicit --mode=ithreads is respected' );
}

# Explicit --mode=single is always respected
{
    my $single = Net::Daemon->new(
        {
            'localport' => 0,
            'proto'     => 'tcp',
        },
        ['--mode=single']
    );
    is( $single->{'mode'}, 'single',
        'explicit --mode=single is respected' );
}

done_testing;
