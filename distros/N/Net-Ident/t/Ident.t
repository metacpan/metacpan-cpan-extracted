# -*- Perl -*-
# Integration tests for Net::Ident — requires a running identd to do
# meaningful testing.  When no identd is reachable, the network-dependent
# tests are gracefully skipped.
#
# Originally written 1999, modernised to Test::More 2026.

use strict;
use warnings;

use Test::More;
use Net::Ident qw(:fh ident_lookup);
use FileHandle;
use Socket;

# Pipe-fork to prefix debug output with "# " so it disappears in
# non-verbose TAP runs.  Skip the fork on platforms that lack it.
my $debug_ok = 0;
if ( $^O ne 'MSWin32' ) {
    if ( open( my $debugfh, '|-' ) ) {
        # parent
        $debugfh->autoflush(1);
        *Net::Ident::STDDBG = *$debugfh;
        $Net::Ident::DEBUG  = 2;
        $debug_ok = 1;
    }
    else {
        # child — prefix every line with "# "
        $| = 1;
        while (<STDIN>) {
            s/^/# /;
            print;
        }
        exit 0;
    }
}

# Locate the hosts file listing machines to test against.
my ($hostsfile) = grep { -r } qw( t/hosts hosts ../t/hosts );
my @hosts;
if ( $hostsfile && open( my $fh, '<', $hostsfile ) ) {
    @hosts = grep { !/^#/ && /\S/ } <$fh>;
    chomp @hosts;
    close $fh;
}
@hosts = ('127.0.0.1') unless @hosts;

# Try connecting to identd (port 113) on each host.  Also try to
# obtain a "connection refused" handle by connecting to the telnet
# port on a host whose identd is down.
$SIG{ALRM} = sub { 0 };

my $tcpproto  = ( getprotobyname('tcp') )[2] || 6;
my $identport = ( getservbyname( 'ident', 'tcp' ) )[2] || 113;

my ( $connok, $connokhost, $connrefuse, $connrefusehost );

for my $host (@hosts) {
    diag "trying to resolve $host...";
    my $addr = inet_aton($host) or next;

    my $fh = FileHandle->new;
    socket( $fh, PF_INET, SOCK_STREAM, $tcpproto )
      or die "socket: $!";

    diag "connecting to " . inet_ntoa($addr) . ":$identport";
    alarm(10);
    if ( connect( $fh, sockaddr_in( $identport, $addr ) ) ) {
        alarm(0);
        diag "connected to identd on $host";
        $connok     ||= $fh;
        $connokhost ||= $host;
    }
    else {
        my $err = "$!";
        alarm(0);
        if ( $err =~ /connection refused/i ) {
            diag "identd connection refused on $host, trying telnet port";
            $fh = FileHandle->new;
            socket( $fh, PF_INET, SOCK_STREAM, $tcpproto )
              or die "socket: $!";
            alarm(10);
            if ( connect( $fh, sockaddr_in( 23, $addr ) ) ) {
                alarm(0);
                diag "connected to telnet on $host";
                $connrefuse     ||= $fh;
                $connrefusehost ||= $host;
            }
            else {
                alarm(0);
                diag "telnet connect failed: $!";
            }
        }
        else {
            diag "connect failed: $err";
        }
    }
    last if $connok && $connrefuse;
}

if ( !$connok && !$connrefuse ) {
    diag "WARNING: no identd or telnet host reachable — most tests will be skipped";
}

# --- Identd-available tests ---

SKIP: {
    skip "no identd connection available", 6 unless $connok;

    diag "running ident lookups via $connokhost";

    # 1. FH->ident_lookup method
    my $username = $connok->ident_lookup(30);
    ok( $username, "FH->ident_lookup returned a username ($username)" );

    # 2. Net::Ident::lookup function
    my $username2 = Net::Ident::lookup( $connok, 30 );
    is( $username2, $username, 'Net::Ident::lookup matches FH method' );

    # 3. ident_lookup with an unqualified filehandle
    {
        no strict 'refs';
        *FH = $connok;
        *FH = \1;    # prevent "used only once" warning
    }
    my $username3 = ident_lookup( 'FH', 30 );
    is( $username3, $username, 'ident_lookup(unqualified FH) matches' );

    # 4-5. Asynchronous interface: initiate, then close original socket
    my $lookup = Net::Ident->new( $connok, 30 );
    ok( $lookup, 'Net::Ident->new succeeds' );
    ok( $lookup->getfh && !$lookup->geterror,
        'new object has fh and no error' );

    # Close the original connection so the remote identd returns ERROR
    shutdown( $connok, 2 );
    close($connok);
    sleep 1;

    # 6. The lookup should now fail (remote port gone)
    my ( $user, $opsys, $error ) = $lookup->username;
    diag "remote identd said: " . ( $error // '<undef>' );
    ok( !defined $user && defined $opsys && $opsys eq 'ERROR',
        'lookup fails with ERROR after closing original socket' );
}

# --- Connection-refused tests ---

SKIP: {
    skip "no connection-refused host available", 1 unless $connrefuse;

    diag "testing connection-refused via $connrefusehost";
    my ( $user, $opsys, $error ) = $connrefuse->ident_lookup(30);
    ok( !defined $user && !defined $opsys && $error =~ /connection refused/i,
        "connection refused error: $error" );
}

# --- Non-socket handle (always runs) ---

{
    my $lookup = Net::Ident->new( \*STDERR, 30 );
    ok( $lookup, 'new() on non-socket returns an object (never dies)' );
    is( $lookup->getfh, undef, 'getfh returns undef for non-socket' );
    ok( $lookup->geterror, 'geterror reports the failure: ' . ( $lookup->geterror // '' ) );
}

done_testing;
