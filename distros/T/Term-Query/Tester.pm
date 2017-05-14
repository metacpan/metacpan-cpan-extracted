# Tester.pm module

# $Id$
#
# This package is designed to run tests on modules which
# perform interactively.

package Tester;

@ISA = qw( Exporter );
@EXPORT = qw( run_test_with_input run_class_test );

# run_test_with_input $class, $testno, $input, 
#		      \&testsub, $testargsref, $condition.

sub run_test_with_input {
    my $class = shift;
    my $test = shift;
    my $inputstring = shift;
    my $testsub = shift;
    my $testargs = shift;
    my $condition = shift;

    if (!ref($testsub) and $testsub !~ /::/) {
	my $pkg = (caller)[0];
	my $i;
	for ($i = 1; $pkg = (caller)[0]; $i++) {
	    last unless $pkg eq 'Tester';
	}
	$testsub =~ s/^/$pkg::/;	# qualify the sub
    }

    select(STDOUT); $| = 1;
    printf STDOUT "%d.......", $test;

    $SIG{'PIPE'} = 'IGNORE';	# don't let pipe errors hurt us
    pipe(TESTREAD, CHILDWRITE);
    pipe(CHILDREAD, TESTWRITE);
    if (!fork) {
	open(STDIN, "<&CHILDREAD");
	open(STDOUT, ">&CHILDWRITE");	select(STDOUT); $| = 1;
	open(STDERR, ">&STDOUT");	select(STDERR); $| = 1;
	close CHILDREAD;
	close CHILDWRITE;
	select(STDOUT); $| = 1;

	# Finally, after all that -- run the actual test subroutine
	my $sub = eval 'sub { package main; &{$_[0]}(@{$_[1]}); }';
	$_ = &$sub($testsub, $testargs);

	# The condition must be evaluated here, in the child
	# process -- since it may involve variables which have
	# been set in the child (but not the parent)
	if ($condition) {
	    my $sub = eval 
		'sub { package main;
		       ref($_[0]) eq "CODE" ? &{$_[0]} : eval $_[0]; }';
	    &$sub($condition) or print "Condition failed\n";
	}
	close STDOUT;
	close STDIN;
	exit;
    }
    close CHILDREAD;
    close CHILDWRITE;

    # Generate the output
    print TESTWRITE $inputstring."\n";
    close TESTWRITE;		# will cause an EOF
    
    my @output;
    while (<TESTREAD>) {	# Now get the results
	push(@output, $_);
	print if $Details > 1;
    }
    close TESTREAD;
    $SIG{'PIPE'} = 'DEFAULT';	# normal pipe stuff

    # If reference output doesn't exist, generate it from our
    # current input
    my $testdir = -d "t" ? "t" :
		  -d "../t" ? "../t" :
		  -d "../../t" ? "../../t" :
		  die "Can't find 't'!\n";
    my $testref = "$testdir/$class.$test.ref";
    my $testout = "$testdir/$class.$test.out";
    my @Details = ();

    if (! -f $testref) {
	push(@Details,"Generated reference output.") if $Details > 1;
	open(NEWREF,">$testref");
	print NEWREF @output;
	close NEWREF;
    }

    if (open(OUT,">$testout")) {
	print OUT @output;
	close OUT;
    } else {
	die "Cannot open output file: $testout: $!\n";
    }

    open(REF,$testref) or die "Can't open '$testref': $!\n";

    my $notok = '';
    my $refout;

    for ($i = 0; $i <= $#output; $i++) {
	length($refout = <REF>) || last;
	$notok++ if $output[$i] =~ /condition failed/i;
	next if $output[$i] eq $refout;
	$notok++;
	if ($Details) {
	    push(@Details, sprintf("line %d: \"%s\"", $i, $output[$i]));
	    push(@Details, sprintf("should be: \"%s\"", $refout));
	}
	last;
    }
    if ( $i <= $#output) {
	$notok++;
	push(@Details, "reference output has less lines.") if $Details;
    } elsif ( !eof(REF) ) {
	$notok++;
	push(@Details, "reference output has more lines.") if $Details;
    }
    close REF;
    if ($notok) {
	print "not ok\n";
    } else {
	print "ok\n";
	unlink $testout;
    }
    print "\t".join("\n\t", @Details)."\n" if @Details;
    undef @Details;
}

# Run a class of tests
# Just like the Perl tests

# run_test_class class_name;
#
# * The file testdir/$class.pl must exist
# * The subroutine &$class_Tests will be invoked.

sub run_class_test {
    my $class = shift;
    my $testdir = -d "t" ? "t" :
		  -d "../t" ? "../t" :
		  -d "../../t" ? "../../t" :
		  die "Can't find 't'!\n";
    my $testmodule = "$testdir/$class.pl";
    my $failed;

    if ( ! -f $testmodule ) {
	print STDERR "No such test for class: $class.\n";
	return;
    }

    select(STDOUT); $| = 1;
    print substr($class.('.' x 15),0,15);
    if (!(open(STDIN,"-|"))) {
	open(STDIN,"/dev/null");
	open(STDERR,">&STDOUT");
	select(STDERR); $| = 1;
	select(STDOUT); $| = 1;

	do $testmodule;		# execute the test code

	exit;
    }

    my( $range, $begin, $end );
    my( $test, $status );

    $range = <STDIN>; 	# get the test range
    if ($range =~ /^(\d+)\.\.(\d+)/) {
	($begin, $end) = ($1, $2);
    } else {
	# Non-standard test output -- print it, and exit.
	do { print "! $_\n"; } while ($_ = <STDIN>);
	return;
    }
    @Test{$begin .. $end} = ($begin .. $end);
    while (<STDIN>) {
	chomp;
	if (s/^(\d+)\.+((?:not )?ok)\s*//) {
	    ($test, $status) = ($1, $2);
	    $Test{$test} = $status;
	    if ($status eq 'not ok') {
		$Test{$test} .= ": ".$_ if length;
		$failed++;
	    }
	} elsif ($test) {
	    $Test{$test} .= "\n".$_;
	} else {
	    print "! $_\n";
	}
    }
    close STDIN;
    if ($failed) {
	my @failed = grep($Test{$_} =~ /not/, keys %Test);
	my @msgs = @Test{@failed};
	if ($#failed == $[) {
	    printf "Test %s failed %s", $failed[0], $Test{$failed[0]};
	} else {
	    my $last = pop @failed;
	    printf "Tests %s and %s failed", join(", ", @failed), $last;
	    push(@failed, $last);
	}
	foreach (@msgs) { s/not ok[:,\s;]*//; }
	@msgs = grep(/./,@msgs);
	if (@msgs) {
	    printf ":\n\t".join("\n\t", @msgs)."\n" if @msgs;
	} else {
	    print ".\n";
	}
	foreach $test (@failed) {
	    $testout = "$testdir/$class.$test.out";
	    next unless -f $testout;
	    open(OUT,$testout) or next;
	    print "Test $test results:\n";
	    while (<OUT>) { print "\t".$_; }
	    close OUT;
	}
	exit unless $KeepGoing;
    } else {
	print "ok\n";
    }
}

1;
