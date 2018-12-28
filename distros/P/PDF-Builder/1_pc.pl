#!/usr/bin/perl
# run perlcritic test suite
#   needless to say, 'perlcritic' command must be installed
# roughly equivalent to pc.bat
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '3.013'; # VERSION
my $LAST_UPDATE = '3.013'; # manually update whenever code is changed

# command line:
# -5  run perlcritic -5 .  (should pass)
# -5x                      exclude certain common errors
# -4  run perlcritic -4 .  should get a number of common errors
# -4x                      exclude certain common errors
# -3  run perlcritic -3 .  should get a number of errors
# -3x                      exclude certain common errors
# -2  run perlcritic -2 .  should get more errors
# -2x                      exclude certain common errors
# -1  run perlcritic -1 .  should get even more errors
# -1x                      exclude certain common errors
# 
# levels 1,2,3 are only for the morbidly curious!

# output <source name> OK is always ignored
my @ignore_list = (
     "Code before warnings",  # due to use of "no warnings" pragma 
     "Warnings disabled at",  # due to use of "no warnings" pragma
     "Close filehandles as soon as possible", 
                              # it thinks there is no "close" on an open 
			      # filehandle, due to either too many lines for 
			      # it to buffer, or use of other code to close
     "Always unpack ",        # Always unpack @_ first at line
                              # not using @_ or $_[n] directly is good practice,
                              # but it doesn't seem to recognize legitimate uses
     "Subroutine name is a homonym for builtin function", 
                              # e.g., we define "open" when there is already a 
			      # system (CORE::) open (ambiguous unless CORE:: 
			      # added)
     "Symbols are exported by default", 
                              # it doesn't like something about our use of 
			      # @EXPORT and @EXPORT_OK
	          );

# Note that level 4 includes any level 5 errors, etc.
# 
my $level;
my @exclude;  # leave empty unless "x" suffix
# one command line arg allowed (-4x is default)
if      (scalar @ARGV == 0) {
    $level = '-4';
    @exclude = @ignore_list;
} elsif (scalar @ARGV == 1) {
    if      ($ARGV[0] eq '-5') {
        $level = '-5';
    } elsif ($ARGV[0] eq '-5x') {
        $level = '-5';
        @exclude = @ignore_list;
    } elsif ($ARGV[0] eq '-4') {
        $level = '-4';
    } elsif ($ARGV[0] eq '-4x') {
	# default
        $level = '-4';
        @exclude = @ignore_list;
    } elsif ($ARGV[0] eq '-3') {
        $level = '-3';
    } elsif ($ARGV[0] eq '-3x') {
        $level = '-3';
        @exclude = @ignore_list;
    } elsif ($ARGV[0] eq '-2') {
        $level = '-2';
    } elsif ($ARGV[0] eq '-2x') {
        $level = '-3';
        @exclude = @ignore_list;
    } elsif ($ARGV[0] eq '-1') {
        $level = '-1';
    } elsif ($ARGV[0] eq '-1x') {
        $level = '-1';
        @exclude = @ignore_list;
    } else {
	die "Unknown command line argument '$ARGV[0]'\n";
    }
} else {
    die "0 or 1 argument permitted. -4 is default.\n";
}

my @results = `perlcritic $level .`;
# always remove " source OK"
my @results2 = ();
foreach my $line (@results) { 
    if ($line !~ m/ source OK/) {
	push @results2, $line;
    }
}

if (@ignore_list) {
    @results = @results2;
    @results2 = ();
    # remove common errors
    foreach my $line (@results) {
	my $keep = 1;
	foreach (@ignore_list) {
	    if ($line =~ m/$_/) {
		$keep = 0;
		last;
	    }
	}
	if ($keep) {
	    push @results2, $line;
	}
    }
}

if (scalar(@results2) == 0) {
    print STDERR "No errors reported.\n";
} else {
    print STDERR scalar(@results2)." errors reported:\n";
    print "@results2";
}
