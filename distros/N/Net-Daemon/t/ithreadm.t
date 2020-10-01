#!perl

use strict;
use warnings;

use IO::Socket        ();
use Config            ();
use Net::Daemon::Test ();
use Fcntl             ();

use Config;

$|  = 1;
$^W = 1;

if ( !$Config{useithreads} ) {
    print "1..0 # SKIP This test requires a perl with working ithreads.\n";
    exit 0;
}

if ( $^O eq "MSWin32" ) {
   print  "1..0 # SKIP This test is failing on windows I think due to Win32-Process but it needs help right now.\n";
   exit 0;
}

require threads;

my ( $handle, $port );
if (@ARGV) {
    $port = shift @ARGV;
}
else {
    ( $handle, $port ) = Net::Daemon::Test->Child(
        10,                $^X,              '-Iblib/lib', '-Iblib/arch', 't/server',
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

    #print "Spawning child $i.\n";
    my $tid = threads->new( \&MyChild, $i );
    if ( !$tid ) {
        print STDERR "Failed to create new thread: $!\n";
        exit 1;
    }
    push( @threads, $tid );
}
eval { alarm 1; alarm 0 };
alarm 120 unless $@;
for ( my $i = 1; $i <= 10; $i++ ) {
    my $tid = shift @threads;
    if ( $tid->join() ) {
        print "ok $i\n";
    }
    else {
        print "not ok $i\n";
    }
}

END {
    if ($handle) {
        print "Terminating server.\n";
        $handle->Terminate();
        undef $handle;
    }
    unlink "ndtest.prt";
}
