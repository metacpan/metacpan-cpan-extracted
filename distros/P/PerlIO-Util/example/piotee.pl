#!perl -w

use strict;
use Getopt::Std;
use PerlIO::Util;

main();

sub main{
	getopts 'ainuh', \my %opt_of
		or die "Usage: $0 [-aiun] [FILE]...\n";

	if($opt_of{h}){
		return usage();
	}

	if($opt_of{i}){ # Ignore interrupts
		foreach my $sig(qw(INT TERM HUP QUIT)){
			$SIG{$sig} = 'IGNORE' if exists $SIG{$sig};
		}
	}

	my $mode = $opt_of{a} ? '>>' : '>'; # Append

	if($opt_of{n}){ # No stdout
		return unless @ARGV;

		my $first = shift @ARGV;
		open STDOUT, $mode, $first or die "$0: cannot open $first: $!\n";
	}

	foreach my $file (@ARGV){
		STDOUT->push_layer(tee => $file);
	}

	$| = 1 if $opt_of{u}; # Unbuffered

	while(sysread STDIN, $_, 2**12){
		print;
	}
}


sub usage{
	my $fh = shift;
	print <<"EOT";
Usage: $0 [-aiun] [FILE]...

	-a        append to the given FILEs, do not overwrite
	-i        ignore interrupt signals
	-u        unbuffered output
	-n        do not output to stdout

A tctee(1) clone provided by PerlIO::Util

EOT
}