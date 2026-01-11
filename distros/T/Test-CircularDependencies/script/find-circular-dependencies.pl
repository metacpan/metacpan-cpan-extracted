#!/usr/bin/env perl
use strict;
use warnings;

use Test::CircularDependencies qw(find_dependencies);

use Getopt::Long qw(GetOptions);

GetOptions(
	'dir=s'   => \my @dirs,
	'verbose' => \my $verbose,
	'inc'     => \my $inc,
) or usage();
usage('At least one file or directory must be given') if not @ARGV;

my @loops = find_dependencies( \@ARGV, \@dirs, $verbose, $inc );
foreach my $l (@loops) {
	print "Found loop: @$l\n";
}

sub usage {
	my ($msg) = @_;
	print "----------------\n";

	if ($msg) {
		print "\n$msg\n\n";
	}

	print <<"END";
Usage: $0 <file> | Directory
                       One or more filenames or directory names that provide the tarting place to look for files.
   --dir path/to/dir   Directores where we are looking for dependencies (can be given multiple times).
   --inc               Add the content of \@INC to the list of places where we are looking for dependencies.
   --verbose           Print some log.
END
	exit;
}
