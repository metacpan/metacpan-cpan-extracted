# Test compatibility-mode FH lookups, if enabled.
# Compatibility mode auto-imports ident_lookup into FileHandle.
# When not in compat mode, the test is skipped entirely.

use 5.010;
use strict;
use warnings;

use Test::More;
use Net::Ident;
use Socket;
use FileHandle;

# Check if compatibility mode is active (ident_lookup auto-exported).
if ( !grep { $_ eq '_export_hook_fh' } @Net::Ident::EXPORT ) {
    plan skip_all => 'not in compatibility mode';
}

# Pipe-fork to prefix debug output with "# " (skip on Windows).
if ( $^O ne 'MSWin32' ) {
    if ( open( my $debugfh, '|-' ) ) {
        $debugfh->autoflush(1);
        *Net::Ident::STDDBG = *$debugfh;
        $Net::Ident::DEBUG  = 2;
    }
    else {
        $| = 1;
        while (<STDIN>) {
            s/^/# /;
            print;
        }
        exit 0;
    }
}

# Locate the hosts file.
my ($hostsfile) = grep { -r } qw( t/hosts hosts ../t/hosts );
my @hosts;
if ( $hostsfile && open( my $fh, '<', $hostsfile ) ) {
    @hosts = grep { !/^#/ && /\S/ } <$fh>;
    chomp @hosts;
    close $fh;
}
@hosts = ('127.0.0.1') unless @hosts;

# Try connecting to identd / telnet on hosts.
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
            diag "identd refused on $host, trying telnet port";
            $fh = FileHandle->new;
            socket( $fh, PF_INET, SOCK_STREAM, $tcpproto )
              or die "socket: $!";
            alarm(10);
            if ( connect( $fh, sockaddr_in( 23, $addr ) ) ) {
                alarm(0);
                $connrefuse     ||= $fh;
                $connrefusehost ||= $host;
            }
            else {
                alarm(0);
            }
        }
    }
    last if $connok && $connrefuse;
}

if ( !$connok && !$connrefuse ) {
    diag "WARNING: no identd or telnet host reachable — most tests will be skipped";
}

# --- Compat-mode ident lookup (identd available) ---

SKIP: {
    skip "no identd connection available", 1 unless $connok;

    diag "compat-mode FH->ident_lookup via $connokhost";
    my $username = $connok->ident_lookup(30);
    ok( $username, "compat FH->ident_lookup returned: $username" );
}

# --- Connection-refused test ---

SKIP: {
    skip "no connection-refused host available", 1 unless $connrefuse;

    my ( $user, $opsys, $error ) = $connrefuse->ident_lookup(30);
    ok( !defined $user && !defined $opsys && $error =~ /connection refused/i,
        "compat connection-refused error: $error" );
}

# --- Non-socket handle ---

{
    my ( $user, $opsys, $error ) = STDERR->ident_lookup(30);
    ok( !defined $user && !defined $opsys && $error,
        'compat ident_lookup on non-socket fails gracefully' );
    diag "got: user="
      . ( $user  // '<undef>' ) . " opsys="
      . ( $opsys // '<undef>' ) . " error="
      . ( $error // '<undef>' );
}

done_testing;
