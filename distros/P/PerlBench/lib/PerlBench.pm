package PerlBench;

use strict;
use base 'Exporter';
our @EXPORT_OK = qw(timeit timeit_once make_timeit_sub make_timeit_sub_code);

our $VERSION = "1.006";

use PerlBench::Stats qw(calc_stats);
use PerlBench::Utils qw(sec_f);
use Time::HiRes qw(gettimeofday);
use Carp qw(croak);

=encoding utf8

=head1 NAME

PerlBench - compare several perls's performance

=head1 DESCRIPTION

This module contains timing functions for the various scripts in the
distribution.

See the various programs in this distribution to see what they do
(and maybe help expand this documentation).

=head2 Original README

Perl benchmark suite
--------------------

This is a Perl benchmark suite.  It can be used to compare the
relative speed of different versions of Perl.  You run the benchmark
by starting the 'perlbench-run' script giving the path-name of various
Perls you want to test as argument.  The perlbench-run program takes
the following optional parameters:

  -s               don't scale numbers (so that first perl is always 100)
  -t <filter>      only tests that match <filter> regex are timed
  -c <cpu-factor>  use this factor to scale tests instead of running the
                   'cpu_factor' program to determine it.
  -d <dirname>     what directory to save results in



Creating new tests
------------------

The individual tests are found in a directory called "benchmarks".
They expect to be started with at least a single number as argument.
This number is the CPU speed factor as calculated by the 'cpu_factor'
program.  This factor is used to scale the number of iterations that
the test must run to give measurable timing.

A new test is created by making a new file under the "benchmarks"
directory.  The filename should end with the "*.t" suffix.  A test
should look like this:

  # Name: Regexp matching
  # Require: 4

  require 'benchlib.pl';

  # YOUR SETUP CODE HERE
  $a = 0;

  &runtest(100, <<'ENDTEST');
     # YOUR TESTING CODE HERE
     $a++;  # for instance
  ENDTEST

The first part of the test declares some properties of the test.  The
'require' property means that you need a perl with version number
greater or equal to this to run the test (same as the 'require NUM'
does for perl5).  You are advised to write the tests so that they can
run under perl4 as well as perl5.

You should then load the 'benchlib.pl' library.  This will take care
of the command line arguments and also provide the function
&main::runtest() which will perform the testing.  The first argument
to runtest() is the test scale factor.  It should be set to some
number that makes the test run for about about 10 seconds when given a
proper CPU factor command line argument.  The second argument to
runtest() is the code you want to test.  The code should be suitable
as the body inside a loop.

=cut

sub timeit {
    my($code, %opt) = @_;
    my $init = $opt{init};

    # XXX auto determine how long we need to time stuff
    my $enough = $opt{enough} || 1;

    # auto determine $loop_count and $repeat_count
    print STDERR "# Determine loop count - enough is " . sec_f($enough) . "\n"
	if $opt{verbose};
    my($loop_count, $repeat_count) = do {
	my $count = 1;
	my $repeat = $opt{repeat} || 1;
	while (1) {
	    print STDERR "#  $count ==> " if $opt{verbose};
	    my $t = timeit_once($code, $init, $count, $repeat);
	    print STDERR sec_f($t, undef), "\n" if $opt{verbose};
	    last if $t > $enough;
	    if ($t < 0.00001) {
		$count *= 1000;
		next;
	    }
	    elsif ($t < 0.01) {
		$count *= 2;
		next;
	    }
	    $count = int($count * ($enough / $t) * 1.05) + 1;
	}
	($count, $repeat);
    };

    my @experiment;
    push(@experiment, {
        loop_count => $loop_count,
        repeat_count => $repeat_count,
    });
    $loop_count++ if $loop_count % 2;
    push(@experiment, {
        loop_count => $loop_count / 2,
        repeat_count => $repeat_count * 2,
    });

    my $pl = "tt$$.pl";
    open(my $fh, ">", $pl) || die "Can't create $pl: $!";
    print $fh "#!perl\n";
    print $fh "use strict;\n";
    print $fh "require Time::HiRes;\n";
    print $fh "{\n    $init;\n" if $init;
    print $fh "my \@TIMEIT = (\n";
    for my $e (@experiment) {
	print $fh &make_timeit_sub_code($code, undef, $e->{loop_count}, $e->{repeat_count}), ",\n";
    }
    print $fh ");\n";

    print $fh <<'EOT';

my $e = shift || die;
my $trials = shift || die;
my $loop_count = shift || die;
my @t;
my $sum = 0;
for (1.. $trials) {
    print "t$e=", $TIMEIT[$e-1]->(), "\n";
}
print "---\n";
EOT
    print $fh "}\n" if $init;
    close($fh) || die "Can't write $pl: $!";

    print STDERR "# Running tests...\n" if $opt{verbose};
    my $rounds = 4;
    for my $round (1..$rounds) {
	printf STDERR "#  %.0f%%\n", (($round-1)/$rounds)*100 if $opt{verbose} && $round > 1;
	my $e_num = 0;
	for my $e (@experiment) {
	    $e_num++;
	    open($fh, "$^X $pl $e_num 7 $loop_count |") || die "Can't run $pl: $!";
	    while (<$fh>) {
		#print "XXX $_";
		if (/^t(\d+)=(.*)/) {
		    die unless $1 eq $e_num;
		    my $t = $2+0;
		    push(@{$e->{t}}, $t);
		}
	    }
	    close($fh);
	}
    }
    unlink($pl);
    print STDERR "# done\n" if $opt{verbose};

    for my $e (@experiment) {
	my $t = $e->{t} ||return;
	calc_stats($e->{t}, $e);

	my $count = $e->{loop_count} * $e->{repeat_count};
	$e->{count} = $count;
    }

    my $loop_overhead = do {
	my $e1 = $experiment[0];
	my $e2 = $experiment[-1];
	my $t1 = $e1->{med} / $e1->{loop_count};
	my $t2 = $e2->{med} / $e2->{loop_count};
	my $f = $e2->{repeat_count} / $e1->{repeat_count};
	$f * $t1 - $t2;
    };

    for my $e (@experiment) {
	$e->{loop_overhead} = $loop_overhead * $e->{loop_count};
	$e->{loop_overhead_relative} = $e->{loop_overhead} / $e->{med};
    }

    my %res;
    $res{x} = \@experiment;

    # calculate combined stats
    my @t;
    for my $e (@experiment) {
	my $c = $e->{count};
	my $o = $e->{loop_overhead};
	push(@t, map { ($_-$o)/$c } @{$e->{t}});
    }
    calc_stats(\@t, \%res);

    for my $f (qw(count loop_overhead_relative)) {
	# XXX avg
	$res{$f} = $experiment[0]{$f};
    }

    return \%res;
}

sub timeit_once {
    return make_timeit_sub(@_)->();
}

sub make_timeit_sub {
    my $code = make_timeit_sub_code(@_);
    my $sub = eval $code;
    die $@ if $@;
    return $sub;
}

sub make_timeit_sub_code {
    my($code, $init, $loop_count, $repeat_count) = @_;
    $loop_count = int($loop_count);
    die unless $loop_count > 0;
    die if $loop_count + 1 == $loop_count;  # too large
    $repeat_count ||= 1;
    $init = "" unless defined $init;
    return <<EOT1 . "$init;$code" . <<'EOT2' . ($code x $repeat_count) . <<'EOT3';
sub {
    my \$COUNT = shift || $loop_count;
    \$COUNT++;
    package main;
EOT1

    my($BEFORE_S, $BEFORE_US) = Time::HiRes::gettimeofday();
    while (--$COUNT) {
EOT2

    }
    my($AFTER_S, $AFTER_US) = Time::HiRes::gettimeofday();
    return ($AFTER_S - $BEFORE_S) + ($AFTER_US - $BEFORE_US)/1e6;
}
EOT3
}

1;
