#!/usr/bin/perl
# run examples test suite
# roughly equivalent to examples.bat
#   you will need to update the %args list before running
# author: Phil M Perry
# adapted from PDF::Builder tool suite

use strict;
use warnings;

our $VERSION = '1.004'; # VERSION
our $LAST_UPDATE = '1.004'; # manually update whenever code is changed

# dependent on optional packages:

# command line:
#   -step  = stop after each test to let the tester look at the PDF file
#   -cont  = (default) run continuously to the end, to not tie up tester
#   -A (/^-?A(pi2)?/i) force use of PDF::API2 if installed
#   -B (/^-?B(uilder)?/i) force use of PDF::Builder if installed (default)
my $pause;

my (@example_list, @example_results);
# push @example_list, "010_fonts.pl";
# push @example_results, "show examples of accented and other non-ASCII characters.\n";

  push @example_list, "colspan.pl";
  push @example_results, "demonstrate colspan=n table organization.\n";

  push @example_list, "header.pl";
  push @example_results, "demonstrate column headings.\n";

  push @example_list, "header_repeat_with_cell_props.pl";
  push @example_results, "demonstrate column headings with many properties.\n";

  push @example_list, "row_height.pl";
  push @example_results, "show table with various row heights specified.\n";

  push @example_list, "sample1.pl";
  push @example_results, "show a number of PDF::Table capabilities.\n";

  push @example_list, "chess.pl";
  push @example_results, "show a chessboard with some effects.\n";

  push @example_list, "border_rules.pl";
  push @example_results, "illustrate borders and rules effects.\n";

  push @example_list, "size.pl";
  push @example_results, "illustrate using size setting for column widths.\n";

  push @example_list, "vsizes.pl";
  push @example_results, "illustrate getting table size in advance.\n";

# run with perl examples/<file> [args]

my %args;
# if you do not define a file for a test (leave it EMPTY ''), it will be skipped
# if any spaces in a path, make sure double quoted or use escapes
#
# colspan needs ______ and _________
# $args{'colspan'} = "blah blah";
my $lib = '';  # -A or -B, optional

my $type; # -cont OR -step allowed (default -cont)
# zero or one or two command line flags allowed (zero or one of -A|-B, 
#   zero or one of -cont|-step, -cont is default). then any other args
#   passed on to program.

while (@ARGV) {
    if      ($ARGV[0] =~ m/^-?A(PI2)?/i) {
	$lib = '-A';
    } elsif ($ARGV[0] =~ m/^-?B(uilder)?/i) {
	$lib = '-B';
    } elsif ($ARGV[0] eq '-cont') {
	$type = '-cont';
    } elsif ($ARGV[0] eq '-step') {
	$type = '-step';
    } else {
	last;
    }
    splice @ARGV, 0, 1;  # remove command line arg so <> will work
}
$type ||= '-cont'; # default

$pause = '';
# some warnings:
foreach my $test (@example_list) {
    if ($test eq '______') {
        print "$test: to display the resulting PDFs, you may need to install\n";
        print "  East Asian fonts for your PDF reader.\n";
        $pause = ' ';
    }
}
if ($pause eq ' ') {
    print "Press Enter to continue: ";
    $pause = <>;
}

print STDERR "\nStarting example runs...";

my ($i, $arg);
for ($i=0; $i<scalar(@example_list); $i++) {
    my $file = $example_list[$i];
    my $desc = $example_results[$i];

    if (defined $args{$file}) {
	$arg = $args{$file};
	if ($arg eq '') {
	    print "test examples/$file skipped at your request\n";
	    next;
	}
    } else {
        $arg = '';
    }
    print "\n=== Running test examples/$file $lib $arg\n";
    print $desc;

    system("perl examples/$file $lib $arg");

    if ($type eq '-cont') { next; }
    print "Press Enter to continue: ";
    $pause = <>;
}

