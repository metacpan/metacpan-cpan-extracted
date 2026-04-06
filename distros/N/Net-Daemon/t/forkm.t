# -*- perl -*-

use strict;
use warnings;

use IO::Socket        ();
use Net::Daemon::Test ();
use Fcntl             ();
use POSIX qw/WNOHANG/;
use Test::More;

my $main_pid = $$;
my $ok;
eval {
    if ( $^O ne "MSWin32" ) {
        my $pid = fork();
        if ( defined($pid) ) {
            if ( !$pid ) { exit 0; }    # Child
        }
        wait;
        $ok = 1;
    }
};
if ( !$ok ) {
    plan skip_all => 'This test requires a system with working forks.';
}

plan tests => 10;

my ( $handle, $port );
if (@ARGV) {
    $port = shift @ARGV;
}
else {
    ( $handle, $port ) = Net::Daemon::Test->Child(
        undef,         $^X,              '-Iblib/lib', '-Iblib/arch', 't/server',
        '--mode=fork', 'logfile=stderr', 'debug'
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
    if ( !$fh->print("$j\n") || !$fh->flush() ) {
        die "Child $i: Error while writing $j: " . $fh->error() . " ($!)";
    }
    my $line = $fh->getline();
    die "Child $i: Error while reading: " . $fh->error() . " ($!)"
      unless defined($line);
    my $num;
    die "Child $i: Cannot parse result: $line"
      unless defined( $num = IsNum($line) );
    die "Child $i: Expected " . ( $j * 2 ) . ", got $num"
      unless $j * 2 == $num;
}

sub MyChild {
    my $i = shift;

    eval {
        my $fh = IO::Socket::INET->new(
            'PeerAddr' => '127.0.0.1',
            'PeerPort' => $port
        );
        if ( !$fh ) {
            die "Cannot connect: $!";
        }
        for ( my $j = 0; $j < 1000; $j++ ) {
            ReadWrite( $fh, $i, $j );
        }
    };
    if ($@) {
        print STDERR "Client: Error $@\n";
        return 0;
    }
    return 1;
}

# Spawn 10 children, each running a series of exchanges.
# Children write results to a shared log file; parent collects them.
unlink "log";
my %childs;
for ( my $i = 0; $i < 10; $i++ ) {
    my $pid = fork();
    if ( !defined($pid) ) {
        die "Failed to create new child: $!";
    }
    if ($pid) {
        # Parent
        $childs{$pid} = $i;
    }
    else {
        # Child
        undef $handle;
        %childs = ();
        my $result = MyChild($i);
        require Symbol;
        my $fh = Symbol::gensym();
        if (   !open( $fh, ">>log" )
            || !flock( $fh, 2 )
            || !seek( $fh, 0, 2 )
            || !( print $fh ( ( $result ? "ok " : "not_ok " ), ( $i + 1 ), "\n" ) )
            || !close($fh) ) {
            print STDERR "Error while writing log file: $!\n";
            exit 1;
        }
        exit 0;
    }
}

# Wait for all children to finish
while ( keys(%childs) > 0 ) {
    my $pid = waitpid( -1, 0 );
    last if $pid <= 0;
    delete $childs{$pid} if exists $childs{$pid};
}

# Read results from log file and report via Test::More
my @results;
if ( open( my $log_fh, '<', 'log' ) ) {
    while ( defined( my $line = <$log_fh> ) ) {
        if ( $line =~ /^(ok|not_ok)\s+(\d+)/ ) {
            $results[ $2 - 1 ] = $1 eq 'ok' ? 1 : 0;
        }
    }
    close($log_fh);
}

for ( my $i = 0; $i < 10; $i++ ) {
    ok( $results[$i], "forked child " . ( $i + 1 ) . " exchange (1000 rounds)" );
}

END {
    return unless $$ == $main_pid;
    if ($handle) {
        $handle->Terminate();
        undef $handle;
    }
    while ( my ( $var, $val ) = each %childs ) {
        kill 'TERM', $var;
    }
    %childs = ();
    unlink "ndtest.prt" if -f "ndtest.prt";
    unlink "log"        if -f "log";
}
