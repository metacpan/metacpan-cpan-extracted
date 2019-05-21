#!/usr/bin/perl
# run all "t" tests
# roughly equivalent to t-tests.bat
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '3.015'; # VERSION
my $LAST_UPDATE = '3.013'; # manually update whenever code is changed

# command line:
# -raw   show full output of each t-test run
# -noOK  exclude "ok" lines so can easily spot error lines

my @test_list = qw(
 00-all-usable
 01-basic
 02-xrefstm
 03-xrefstm-index
 annotate
 author-critic
 author-pod-syntax
 barcode
 circular-references
 cmap
 content
 cs-webcolor
 deprecations
 extgstate
 filter-ascii85decode
 filter-asciihexdecode
 filter-runlengthdecode
 font-corefont
 font-synfont
 font-ttf
 font-type1
 gd
 gif
 jpg
 lite
 outline
 page
 papersizes
 pdf
 png
 pnm
 rt67767
 rt69503
 rt120397
 rt120450
 string
 text
 tiff
 viewer-preferences
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

foreach my $file (@test_list) {
    my @results = `perl t/$file.t`;
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
