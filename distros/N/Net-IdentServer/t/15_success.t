
use strict;
use Test;
use IO::Socket::INET;
use Net::IdentServer;

my $kpid = fork;
die "no fork: $!" unless defined $kpid;

unless( $kpid ) {
    alarm 30;
    $SIG{ALRM} = sub { exit 0 };
    $SIG{TERM} = sub { warn "child exit\n"; };
    close STDERR;
    Net::IdentServer->new->run( log_file=>"debug.log", log_level=>4, port=>64999 );
    exit 0;
}

sleep 2;

$SIG{__DIE__} = sub { kill 15, $kpid; exit 1 };
$SIG{ALRM} = sub { die "SIGALRM\n" };
alarm 30;

plan tests => 1;

my $peerport = 64999;
my $open_socket = IO::Socket::INET->new( "localhost:$peerport" );
my $sockport = $open_socket->sockport;

if( my $user = $ENV{USER} ) {
    ok( do_one( "$sockport , $peerport" ), qr($sockport , $peerport : USERID : UNIX : $user) );

} else {
    ok( do_one( "$sockport , $peerport" ), qr($sockport , $peerport : USERID) );
}

sub do_one {
    $\ = "\x0d\x0a";

    my $t = IO::Socket::INET->new( 'localhost:64999' );

    my $msg = shift;
    print $t $msg;
    return scalar <$t>;
}
