#!/usr/bin/env perl
use 5.014;
use warnings;
use FindBin qw($Bin);
use Time::HiRes qw( usleep ualarm gettimeofday tv_interval nanosleep
                    clock_gettime clock_getres clock_nanosleep clock
                    stat);

my ($simulations) = @ARGV;
my $out = '/tmp/temp_fasta_file';
my $min = 10; # Minimum num seqs to simulate
my $max = 10; # Maximum num seqs to simulate
my $M   = 10000; # Maximum seq length in simulation
my $m   = 5;  # Minimum seq length in simulation

say STDERR "Parameter: simulations";
exit unless (defined $simulations);


my $output = `seqkit stats --help | grep tabular | wc -l`;
die "seqkit not found" if ($?);
die "Seqkit not found, or wrong version\n" if ($output ne "1\n");

for (my $n = 1; $n <= $simulations; $n++) {
	my $min_len = int($m * ($n/$simulations));
	my $max_len = int($M * ($n/$simulations));
	my $simula = `perl $Bin/simula_make.pl $min $max $min_len $max_len 2>/dev/null > $out`;

	my $t0 = [gettimeofday];
	my $seqkit = `seqkit stats --tabular --all $out | tail -n 1`;
	#file    format  type    num_seqs        sum_len min_len avg_len max_len Q1      Q2      Q3      sum_gap N50     Q20(%)  Q30(%)
	my $elapsed1 = tv_interval ( $t0, [gettimeofday]);

	my @stats = split /\t/, $seqkit;
	my $N50 = $stats[12];

	$t0 = [gettimeofday];
	my $perl_N50 = `perl $Bin/../bin/n50.pl $out`;
	my $elapsed2 = tv_interval ( $t0, [gettimeofday]);
	chomp($perl_N50);

	if ($N50 == $perl_N50) {
		say "OK\t$n/$simulations\tSeqkit=$N50/$elapsed1\tProch::N50=$perl_N50/$elapsed2\t[$min_len/$max_len]";
	} else {
		die "KO at $n/$simulations: Seqkit=$N50\tProch::N50=$perl_N50\n"
	}
}
