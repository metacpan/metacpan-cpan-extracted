# test compatibility-mode FH lookups, if enabled

# $Id: compat.t,v 1.6 1999/08/02 10:45:46 john Exp $
require 5.004;
use Net::Ident;
use Socket;
use FileHandle;

if ( !grep { $_ eq "_export_hook_fh" } @Net::Ident::EXPORT ) {

    # no default _export_hook_fh in @EXPORT, so we're not in compatibility mode
    print "1..0\n";
    exit 0;
}

# code below is most of the same as ident.t...

# turn on full debugging, but prepend ``# '' to output to make it disappear in
# non-verbose tests
# turn on full debugging, but prepend ``# '' to output to make it disappear in
# non-verbose tests
unless ( open( DEBUGFH, "|-" ) ) {

    # child... do the stuff
    $|++;
    while (<>) {
        s/^/# /;
        print;
    }
    exit 0;
}
DEBUGFH->autoflush(1);
*Net::Ident::STDDBG = *DEBUGFH;
$Net::Ident::DEBUG  = 2;

# find hosts file
my ($hosts) = grep { -r } qw( t/hosts hosts ../t/hosts );
my @hosts;
if ( open( HOSTS, $hosts ) ) {
    @hosts = grep { !/^#/ } <HOSTS>;
    chomp @hosts;
    close HOSTS;
}
else {
    @hosts = qw(127.0.0.1);
}

$SIG{ALRM} = sub { 0 };
$| = 1;

sub bomb ($) { die "# Aargh: @_\n1..1\nnot ok1\n" }

$tcpproto = ( getprotobyname('tcp') )[2] || 6;
$identport = ( getservbyname( 'ident', 'tcp' ) )[2] || 113;
foreach $host (@hosts) {
    print "# trying to resolve $host...\n";
    if ( $addr = inet_aton($host) ) {
        $fh = new FileHandle;
        socket( $fh, PF_INET, SOCK_STREAM, $tcpproto ) or bomb("socket: $!");
        print "# connecting to " . inet_ntoa($addr) . ":$identport\n";
        alarm(10);
        if ( connect( $fh, sockaddr_in( $identport, $addr ) ) ) {
            alarm(0);
            print "# connected\n";
            $connok     ||= $fh;
            $connokhost ||= $host;
        }
        else {
            $e = $!;
            alarm(0);
            if ( $e =~ /connection refused/i ) {
                print "# connection refused\n";

                # try to make a connection to the telnet port instead,
                # to give us some connected filehandle to try the
                # ident lookup on.
                print "# connecting to " . inet_ntoa($addr) . ":23\n";
                $fh = new FileHandle;
                socket( $fh, PF_INET, SOCK_STREAM, $tcpproto )
                  or bomb("socket: $!");
                alarm(10);
                if ( connect( $fh, sockaddr_in( 23, $addr ) ) ) {
                    alarm(0);
                    print "# connected\n";
                    $connrefuse     ||= $fh;
                    $connrefusehost ||= $host;
                }
                else {
                    print "# connect: $!\n";
                    alarm(0);
                }
            }
            else {
                print "# connect: $e\n";
            }
        }
        last if $connok && $connrefuse;
    }
}

$tests = 1;
if ($connok) {
    print "# Will run regular ident lookups by connecting to $connokhost\n";
    $tests++;
}
if ($connrefuse) {
    print "# Will run ``connection refused'' tests by connecting to ", $connrefusehost, "\n";
    $tests++;
}
if ( !$connok && !$connrefuse ) {
    print "# WARNING: not a lot of testing to do without an identd to use!\n";
}
print "1..$tests\n";

$i = 1;
if ($connok) {
    print "# standard lookup test that will succeed, using FH->ident_lookup\n";
    $username = $connok->ident_lookup(30);
    print "not " unless $username;
    print "ok $i\n";
    $i++;
}

if ($connrefuse) {
    print "# try to get a connection refused error\n";
    ( $username, $opsys, $error ) = $connrefuse->ident_lookup(30);

    print "not "
      unless !defined $username
      && !defined $opsys
      && $error =~ /connection refused/i;
    print "ok $i\n";
    $i++;
    print "# got: $error\n";
}

print "# try to get ident info on a something that's not a socket\n";
my ( $user, $opsys, $error ) = STDERR->ident_lookup(30);

print "not " unless !defined $user && !defined $opsys && $error;
print "ok $i\n";
$i++;

for ( $user, $opsys, $error ) {
    $_ = "<undef>" if !defined;
}
print "# got: user=$user opsys=$opsys error=$error\n";
