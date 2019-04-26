#!/usr/bin/env perl

use 5.016;
use Storable qw(retrieve);
use Data::Dumper;
use Term::ANSIColor;
use Getopt::Long;
unless (defined $ARGV[0]) {
die " USAGE: $0 [-f] [-g STR] FILES...

This script will read the data stored in cache files for Proch::Cmd
";
}
my $print_unknown = 0;
my $hint = '';
my $opt_grep = '.';
my $GetOptions = GetOptions(
	'f|full'      => \$print_unknown,
	'g|grep=s'    => \$opt_grep,
);

$hint = 'use -f to print its content' unless ($print_unknown);



foreach my $file (@ARGV) {
	
	if (-r "$file" and ! -d "$file") {
		my $data;
		eval {$data = retrieve($file) };
 
		if ($@) {
			print color('cyan '), "- SKIPPING: $file", color('reset'), " (not a Perl object)\n";
			 
		} else {
			if ($data->{input}->{command}) {
				my $note;
				$note = '(valid content but unexpected filename)' if ($file !~/[a-f0-9]{32}$/);
					
				print color('cyan bold'), "+ READING: $file", color('reset'), " $note\n";
				my $copy = $data;
				my $dump;
				{
					local *STDOUT;
					open STDOUT, '>', \ $dump;
					print Dumper $copy;
				}
				if ($dump =~/$opt_grep/) {
					print color('yellow'), "  SHELL:  ", $data->{input}->{command}, "\n  DESCR: ", $data->{input}->{description}, color('reset') ,"\n";
					print "  FILES: ", join(', ', @{ $data->{input}->{files} }), "\n" if ($data->{input}->{files}[0]);
					print color('bold'), $data->{output}, color('reset');
					$data->{input} = '<...>';
					$data->{output}= '<...>';
					{
						local *STDOUT;
						open STDOUT, '>', \ $dump;
						print Dumper $data;
					}
					print $dump;
				} else {
					print "<$opt_grep> not found in $file\n";
				}
			} else {
				print color('cyan '), "- SKIPPING: $file", color('reset'), " (unknown Perl object$hint)\n";
				print Dumper $data if ($print_unknown);
			}
		}

	} else {
		print color('cyan '), "- SKIPPING: $file", color('reset'), " (not readable)\n" if (-f "$file");
	}
}
