use Regex::PreSuf;
chdir 't' or die "$0: chdir: $!\n";

print "1..1\n";

my $test = 1;

print STDERR "# Hang on, collecting words for the next test...\n";

my %words;

if (open(WORDS, "words.txt")) {
    while (<WORDS>) {
	chomp;
	$words{$_}++;
    }
    close(WORDS);
} else {
    die "$0: wordst.txt: $!\n";
}

my @words = keys %words;

# @words = grep { rand() < 0.10 } @words;

printf STDERR "# Found %d words.\n", scalar @words;

use Benchmark;

if (@words) {
    print STDERR "# NOTE THAT THIS TEST WILL TAKE SEVERAL MINUTES.\n";
    print STDERR "# And I do mean *SEVERAL* minutes.\n";
    print STDERR "# We will test all the letters from 'a' to 'z',\n";
    print STDERR "# both as the first and the last letters.\n";
    my $ok = 0;
    my @az = ("a".."z");

    my $N0 = 2 * @words;
    my $N1;	
    my $c;
    my @a;
    my @c;
    my $T0 = time();
 
    # I'm trying to get 0 elapsed time to initialize some timesum counters here.
    # Is there a better way?
    my $t1=new Benchmark;
    my $t2=$t1;

    # Initialized to 0, updated by each run of doit.
    my $naiveCreationTotal=timediff($t1,$t2);
    my $naiveExecutionTotal=timediff($t1,$t2);
    my $presufCreationTotal=timediff($t1,$t2);
    my $presufExecutionTotal=timediff($t1,$t2);

    sub doit {
	my ($t0, $t1);
	$t0 = new Benchmark;
	my $b  = join("|", @a);
	$t1 = new Benchmark;
	my $tb = timediff($t1, $t0);
        $naiveCreationTotal=Benchmark::timesum($tb,$naiveCreationTotal);
	print STDERR "# Naive/create:   ", timestr($tb), "\n";
	print STDERR "# Naive/execute:  ";
	$t0 = new Benchmark;
	my @b = grep { /^(?:$b)$/ } @words;
	$t1 = new Benchmark;
        $tb=timediff($t1,$t0);
        $naiveExecutionTotal=Benchmark::timesum($tb,$naiveExecutionTotal);
        print STDERR timestr($tb), "\n";
	$t0 = new Benchmark;
	my $c  = presuf(@a);
	$t1 = new Benchmark;
	my $tc = timediff($t1, $t0);
        $presufCreationTotal=Benchmark::timesum($tc,$presufCreationTotal);
	print STDERR "# PreSuf/create:  ", timestr($tc), "\n";
	print STDERR "# PreSuf/execute: ";
	$t0 = new Benchmark;
	@c = grep { /^(?:$c)$/ } @words;
	$t1 = new Benchmark;
        $tc = timediff($t1, $t0);
        $presufExecutionTotal=Benchmark::timesum($tc,$presufExecutionTotal);
        print STDERR timestr($tc), "\n";

	print STDERR "# Aggregate times so far:\n";
	print STDERR "# Naive/create:   ",timestr($naiveCreationTotal),"\n";
	print STDERR "# Naive/execute:  ",timestr($naiveExecutionTotal),"\n";
	print STDERR "# Presuf/create:  ",timestr($presufCreationTotal),"\n";
	print STDERR "# PreSuf/execute: ",timestr($presufExecutionTotal),"\n";
    }

    sub checkit {
	if (@c == @a && join("\0", @a) eq join("\0", @c)) {
	    $ok++;
	} else {
	    print STDERR "# PreSuf FAILED!\n";
	    my %a; @a{@a} = ();
	    my %c; @c{@c} = ();
	    my %a_c = %a; delete @a_c{keys %c};
	    my %c_a = %c; delete @c_a{keys %a};
	    if (keys %a_c) {
		print STDERR "# MISSED:\n";
		foreach (sort keys %a_c) {
		    print STDERR "# $_\n";
		}
	    }
	    if (keys %c_a) {
		print STDERR "# MISTOOK:\n";
		foreach (sort keys %c_a) {
		    print STDERR "# $_\n";
		}
	    }
	}
    }

    sub estimateit {
	$N1 += @a;
	my $dt = time() - $T0;
	if ($N1 && $dt) {
	    print STDERR "# Estimated remaining testing time: ",
	                 int(($N0 - $N1)/($N1/$dt)), " seconds.\n";
	}
    }

    foreach $c (@az) {
	@a  = grep { /^$c/  } @words;
	if (@a) {
	    print STDERR "# Testing ", scalar @a," words beginning with '$c'...\n";
	    doit();
	    checkit();
	} else {
	    print STDERR "# No words beginning with '$c'...\n";
	    $ok++; # not a typo
	}
	estimateit();

	@a  = grep { /$c$/  } @words;
	if (@a) {
	    print STDERR "# Testing ", scalar @a," words ending with '$c'...\n";
	    doit();
	    checkit();
	} else{
	    print STDERR "# No words ending with '$c'...\n";
	    $ok++; # not a typo
	}
	estimateit();
    }

    print STDERR "#\n";
    print STDERR "# Aggregate times total:\n";
    print STDERR "#\n";
    print STDERR "# Naive/create:   ",timestr($naiveCreationTotal),"\n";
    print STDERR "# Naive/execute:  ",timestr($naiveExecutionTotal),"\n";
    print STDERR "# PreSuf/create:  ",timestr($presufCreationTotal),"\n";
    print STDERR "# PreSuf/execute: ",timestr($presufExecutionTotal),"\n";

    my $naiveTotal  = Benchmark::timesum($naiveCreationTotal,$naiveExecutionTotal);
    my $presufTotal = Benchmark::timesum($presufCreationTotal,$presufExecutionTotal);
    print STDERR "#\n";
    print STDERR "# Naive/total:    ",timestr($naiveTotal),"\n";
    print STDERR "# PreSuf/total:   ",timestr($presufTotal),"\n";
    print STDERR "#\n";
    printf STDERR "# PreSuf speedup = %.2f (more than one is better)\n",
	$naiveTotal->cpu_a / $presufTotal->cpu_a;
    print STDERR "#\n";

    print "not " unless $ok == 2 * @az;
    print "ok ", $test++, "\n";
} else {
    print "ok ", $test++, "# skipped: no words found\n";
}

