#!/usr/bin/perl
use strict;
use warnings;

use Term::ProgressBar 2.00;

my $input_file = shift;
my $output_file = shift;
my $in_fh = \*STDIN;
my $out_fh = \*STDOUT;
my $message_fh = \*STDERR;
my $num_lines = -1;

if(defined($input_file) and $input_file ne '-') {
	open($in_fh, $input_file) or die "Couldn't open file, '$input_file', for reading: $!";
	my $wc_output = `wc -l $input_file`;
	chomp($wc_output);
	$wc_output =~ /^\s*(\d+)(\D.*)?/ or die "Couldn't parse wc output: $wc_output";
	$num_lines = $1;
}

if(defined($output_file)) {
	!-f $output_file or die "Specified output file, '$output_file', already exists";
	open($out_fh, '>', $output_file) or die "Couldn't open output file, '$output_file', for writing: $!";
}

my $progress = Term::ProgressBar->new({
	name	=> 'file processor',
	count	=> $num_lines,
	remove	=> 1,
	fh		=> $message_fh,
});

while(my $line = <$in_fh>) {
	chomp($line);
	print $out_fh "I found a line: $line\n";
	$progress->message("Found 10000!") if($line =~ /10000/);
	$progress->update();
}

$progress->update($num_lines);

print $message_fh "Finished\n";
