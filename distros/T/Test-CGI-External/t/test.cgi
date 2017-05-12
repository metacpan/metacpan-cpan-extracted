#!/home/ben/software/install/bin/perl

# This is a deliberately-misbehaving CGI script, the "bad boy" of CGI
# scripting. The bad behaviour is controllable by command-line options.

use warnings;
use strict;
use FindBin '$Bin';
use Getopt::Long;

# Get what kind of bad behaviour to exhibit

GetOptions (
    # Stray garbage in header
    "header" => \my $header,
    # Don't print gzip header but print gzip contents
    "gzip" => \my $gzip,
    # Print a header indicating gzip but send uncompressed.
    "gzipheader" => \my $gzipheader,
    # Give a bad exit code
    "exit" => \my $exit,
    # Omit charset
    "charset" => \my $charset,
    # Give a bad charset
    "badcharset" => \my $badcharset,
    # Don't print content type
    "contenttype" => \my $contenttype,
);

my $outputcharset = '; charset=';
if ($badcharset) {
    $outputcharset .= 'OhNoThisCharsetIsBad';
}
else {
    $outputcharset .= 'UTF-8';
}
if ($header) {
    print "Oops! There is garbage in your CGI header!\n";
}
if ($charset) {
    $outputcharset='';
}

if (! $contenttype) {
    print "Content-Type: text/html$outputcharset\n";
}
else {
    # Print a header so we don't trip other tests off.
    print "Location: http://www.example.com\nStatus: 301 Ho Ho Ho\n";
}
if ($gzip) {
    if (! $gzipheader) {
	print "Content-Encoding: gzip\n";
    }
}
print "\n";

if (! $gzip) {
    if ($contenttype) {
	print "What type might this be?\n";
    }
    else {
	print "Welcome to your web page\n";
    }
}
else {
    if ($gzipheader) {
	print "Welcome to your web page\n";
    }
    else {
	open my $in, "<:raw", "$Bin/test.gz" or die $!;
	while (<$in>) {
	    print;
	}
	close $in or die $!;
    }
}

if ($exit) {
    exit (1);
}
else {
    exit;
}

