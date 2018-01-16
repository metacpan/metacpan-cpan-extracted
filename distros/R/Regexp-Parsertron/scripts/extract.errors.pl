#!/usr/bin/env perl

use v5.018;

use File::Slurper 'read_lines';

# -----------------------------

my($input_file)	= './xt/author/generate.tests.log';
my(@lines)		= read_lines($input_file);

my($count);

say "my(%perl_failure)\t\t=";
say "(\t# For V 5.20.2.";

for my $line (@lines)
{
	next if ($line !~ /1 Error str: (\d+): Perl/);

	$count = $1;

	if ($count < 100)
	{
		$count = "  $count";
	}
	elsif ($count < 1000)
	{
		$count = " $count";
	}

	say "\t$count => 1,";
}

say ");\n";
say "my(%marpa_failure) =";
say "(\t# For V 5.20.2.";

for my $line (@lines)
{
	$count = $1 if ($line =~ /Test count: (\d+)\./);

	next if ($line !~ /Parse failed. Error in SLIF parse/);

	if ($count < 100)
	{
		$count = "  $count";
	}
	elsif ($count < 1000)
	{
		$count = " $count";
	}

	say "\t$count => 1,";
}

say ");\n";
