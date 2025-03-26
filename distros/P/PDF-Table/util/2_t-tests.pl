#!/usr/bin/perl
# run all "t" tests
# must be run from parent of t/
# author: Phil M Perry
# adapted from PDF::Builder tool suite

use strict;
use warnings;

our $VERSION = '1.007'; # VERSION
our $LAST_UPDATE = '0.12'; # manually update whenever code is changed

my $perl = 'perl';  # run Perl command. add path, etc. if needed

# command line flags, mutually exclusive:
# -raw   show full output of each t-test run
# -noOK  exclude "ok" lines so can easily spot error lines  DEFAULT

my @test_list = qw(
 Basics
 Colspan
 PDF-Table
 table
                  );
# override full list above, and run just one or two tests
#@test_list = qw( Colspan );
		  
# moved to xt/
#   manifest
#   pod

my @need_T = qw(
 Colspan
 manifest
               );

# perl t/<name>.t will run it

my $type;
# one command line arg allowed (-noOK is default)
if      (scalar @ARGV == 0) {
    $type = '-noOK';
} elsif (scalar @ARGV == 1) {
    if      ($ARGV[0] eq '-raw') {
        $type = '-raw';
    } elsif ($ARGV[0] eq '-noOK') {
	# default
        $type = '-noOK';
    } else {
	die "Unknown command line argument '$ARGV[0]'\n";
    }
} else {
    die "0 or 1 argument permitted. -noOK is default.\n";
}

my $TT = '';
foreach my $file (@test_list) {
    $TT = '';
    foreach (@need_T) {
	if ($_ eq $file) {
	    $TT = '-T';
	    last;
	}
    }

    my @results = `$perl $TT t/$file.t`;
    # TBD: detect if a FAILED test, and remark at end if any failures
    print "\nt/$file.t\n";
    if ($type eq '-raw') {
	print "@results";
    } else {
	# -noOK   remove any lines which start with "ok"
	foreach my $line (@results) {
	    if ($line !~ m/^ok/) {
		print $line;
	    }
	}
    }
	
}
