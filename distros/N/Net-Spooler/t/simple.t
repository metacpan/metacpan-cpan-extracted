# -*- perl -*-
#
#   A simple test for the Net::Spooler class.
#

use strict;
use IO::Socket ();
use Config ();
use Net::Spooler::Test ();
use File::Path ();

my $numTests = 31;
my $runDir = "tmp";
my $rmRunDir = 0;


-d $runDir || mkdir($runDir, 0755) ||
    die "Failed to create directory $runDir: $!";

my($handle, $port);
if (@ARGV) {
    $port = shift @ARGV;
} else {
    my $cmd = qq{--spool-command=$^X -Iblib/lib -Iblib/arch ../t/process}
	       . qq{ --file=\$file\$};
    ($handle, $port) =
	Net::Spooler::Test->Child($numTests,
				  $^X, '-Iblib/lib', '-Iblib/arch',
				  't/server', '--mode=single',
				  "--spool-dir=$runDir",
				  "--maxsize=200", '--debug',
				  "--admin=joe", $cmd,
				  '--timeout', 60);
}

unlink "tmp/process.res" if -f "tmp/process.res";

# Generate 10 random numbers ...
my @numbers;
for (my $i = 0;  $i < 10;  $i++) {
    push(@numbers, int(rand(10000))+1);
}

# Pass the 10 numbers ...
my $tnum = 0;
for (my $i = 0;  $i < 10;  $i++) {
    print "Making connection $i to port $port...\n";
    my $fh = IO::Socket::INET->new('PeerAddr' => '127.0.0.1',
				   'PeerPort' => $port);
    ++$tnum; printf("%s $tnum\n", $fh ? "ok" : "not ok");
    my $ok = print $fh "$numbers[$i]\n";
    ++$tnum; printf("%s $tnum\n", $ok ? "ok" : "not ok");
    ++$tnum; printf("%s $tnum\n", $fh->close() ? "ok" : "not ok");
}

my $ok = 0;
my @got;
for (my $i = 0;  $i < 30;  $i++) {
    # Don't trust in the numbering ...
    @got = ();
    if (open(FILE, "<tmp/process.res")) {
	for (my $j = 0;  $j < 11;  $j++) {
	    if (defined(my $line = <FILE>)) {
		if ($line =~ /(\d+)/) {
		    push(@got, $1);
		}
	    }
	}
	my @expected = sort { $a <=> $b } @numbers;
	@got = sort { $a <=> $b } @got;
	if (@expected == @got) {
	    $ok = 1;
	    for (my $j = 0;  $j < @expected;  $j++) {
		$ok = 0 if $expected[$j] != $got[$j];
	    }
	}
	last if $ok;
    }
    sleep 1;
}
++$tnum; printf("%s $tnum\n", $ok ? "ok" : "not ok");
if (!$ok) {
    print "The generated numbers are: ", join(" ", @numbers), "\n";
    print "I've got the numbers: ", join(" ", @got), "\n";
}


END {
    my $h = $handle; undef $handle;
    $h->Terminate() if $h;
    unlink "ndtest.prt" if -f "ndtest.prt";
    unlink "process.res" if -f "process.res" and $rmRunDir;
    File::Path::rmtree($runDir, 0, 1)
	if -d $runDir and $rmRunDir;
}
