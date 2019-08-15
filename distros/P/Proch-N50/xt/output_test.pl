#!/usr/bin/env perl
use 5.012;
use warnings;
use FindBin qw($Bin);
use Term::ANSIColor;
use lib "$Bin/../lib";
use Proch::N50;
my $script = "$Bin/../bin/n50.pl";
my $tests  = "$Bin/outputs/";
my $mkdir = `mkdir -p "$tests"`;
die "Unable to make directory: $tests" if ($?);
my $v = $Proch::N50::VERSION;
my $overwrite = 1;

say color('green bold'), "TESTING $v", color('reset');
my @input = ("$Bin/../data/test.fa", "$Bin/../data/small_test.fa  $Bin/../data/test.fa");
my %params = (
	'default'             => '-b',
	'json'   	      => '-b --format json',
	'tsv by size',        => '-b --format tsv -o size',
	'screen by rev name ' => '-b --format screen -o path -r',
);

foreach my $p (sort keys %params) {
	say color('bold'), $p, ' ', color('blue'), $params{$p}, color('reset');
	foreach my $i (@input) {
		my $dataset_label = input_label($i);
		my $test_tag = $p;
		$test_tag =~s/\s+/-/g;
		my $filename = "${test_tag}_${dataset_label}_${v}.txt";
		say color('cyan bold'), $dataset_label, color('reset cyan'), " ", $i, color('reset');
		if (-e "$tests/$filename" and not $overwrite) {
			print STDERR " [WARNING] $filename found: skipping\n";
		} else {
			say `$script $params{$p} $i > "$tests/$filename"` ;
		}
		my @list  = sort glob "$tests/${test_tag}_${dataset_label}_*.txt";
		for (my $i = 0; $i < $#list; $i++) {
			my $first = $list[$i];
			my $second = $list[$i + 1];
			next unless (-e $second);
			`diff "$first" "$second" > /dev/null`;
			say color('red'), 'DIFFERENCE', color('reset'), " - $first != $second";
		}
	}
}



sub input_label {
	my $i = shift @_;
	my @files = split /\s/, $i;
	return 'null' if (not defined $files[0]);
	return 'single' if ($#files == 0);
	return 'multi';
}
