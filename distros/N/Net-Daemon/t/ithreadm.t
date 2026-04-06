#!perl

use strict;
use warnings;

use IO::Socket        ();
use Config            ();
use Net::Daemon::Test ();
use Fcntl             ();
use Test::More;

$| = 1;

if ( !$Config::Config{useithreads} ) {
    plan skip_all => 'This test requires a perl with working ithreads.';
}

# Perl ithreads on Windows use DuplicateHandle() to clone file descriptors
# into new threads.  MSDN explicitly states that DuplicateHandle must not
# be used with Winsock SOCKETs — WSADuplicateSocket() is required instead.
# Since Perl core does not use WSADuplicateSocket, accepted client sockets
# get corrupted when cloned into handler threads, causing sporadic
# "Invalid argument" errors during socket I/O.  This is a Perl core
# limitation, not a Net::Daemon bug.  See #19, #30.
if ( $^O eq "MSWin32" ) {
    print "1..0 # SKIP Perl ithreads on Windows cannot safely duplicate Winsock sockets (DuplicateHandle vs WSADuplicateSocket)\n";
    exit 0;
}

require threads;

plan tests => 10;

my ( $handle, $port );
if (@ARGV) {
    $port = shift @ARGV;
}
else {
    ( $handle, $port ) = Net::Daemon::Test->Child(
        undef,             $^X,              '-Iblib/lib', '-Iblib/arch', 't/server',
        '--mode=ithreads', 'logfile=stderr', 'debug'
    );
}

sub IsNum {
    my $str = shift;
    ( defined($str) && $str =~ /(\d+)/ ) ? $1 : undef;
}

sub ReadWrite {
    my $fh = shift;
    my $i  = shift;
    my $j  = shift;
    die "Child $i: Error while writing $j: $!"
      unless $fh->print("$j\n")
      and $fh->flush();
    my $line = $fh->getline();
    die "Child $i: Error while reading: " . $fh->error() . " ($!)"
      unless defined($line);
    my $num = IsNum($line);
    die "Child $i: Cannot parse result: $line"
      unless defined($num);
    die "Child $i: Expected " . ( $j * 2 ) . ", got $num"
      unless ( $num == $j * 2 );
}

sub MyChild {
    my $i = shift;

    eval {
        my $fh = IO::Socket::INET->new(
            'PeerAddr' => '127.0.0.1',
            'PeerPort' => $port
        );
        die "Cannot connect: $!" unless defined($fh);
        for ( my $j = 0; $j < 1000; $j++ ) {
            ReadWrite( $fh, $i, $j );
        }
    };
    if ($@) {
        print STDERR $@;
        return 0;
    }
    return 1;
}

my @threads;
for ( my $i = 0; $i < 10; $i++ ) {
    my $tid = threads->new( \&MyChild, $i );
    if ( !$tid ) {
        print STDERR "Failed to create new thread: $!\n";
        exit 1;
    }
    push( @threads, $tid );
}
eval { alarm 1; alarm 0 };
alarm 120 unless $@;
for ( my $i = 0; $i < 10; $i++ ) {
    my $tid = shift @threads;
    ok( $tid->join(), "client thread $i completed 1000 round-trips" );
}

END {
    if ($handle) {
        $handle->Terminate();
        undef $handle;
    }
    unlink "ndtest.prt";
}
