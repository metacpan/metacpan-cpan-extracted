#!/usr/local/bin/perl -w
# $Id: cgi_usage.t,v 1.6 2005/03/15 20:59:26 johna Exp $

use strict;
use Log::Trace;
use Test::Assertions 'test';
use Getopt::Std;
use File::Spec;

use vars qw($opt_b $opt_t $opt_T);
getopts('btT');

if ($opt_t) { import Log::Trace 'print'; }
if ($opt_T) { import Log::Trace 'print' => { Deep => 1}; }

plan tests;

#Move into the t directory if we aren't already - makes the test work from the level above
#Do this after plan tests so Test::Assertions doesn't get confused about $0
chdir('t') if(-d 't');
my $cur_dir = File::Spec->curdir();

unshift @INC, "../lib";
require Pod::Usage::CGI;
ASSERT(1, "require Pod::Usage::CGI - v$Pod::Usage::CGI::VERSION");

import Pod::Usage::CGI;
ASSERT(defined &{"pod2usage"}, '... imports pod2usage()');

my $cgi_file = File::Spec->catfile( $cur_dir, 'test_pod_usage.cgi' );
my $output = qx[$^X $cgi_file];
TRACE($^X);

# strip meta tags (contains filepaths, timestamps etc)
$output =~ s/<meta [^>]+\/>//g;
# strip carriage returns (which occur in the header)
$output =~ s/\r//g;

my $exp_file = File::Spec->catfile( $cur_dir, 'test_pod_usage.out' );

#Re-baseline if required
if($opt_b) {
	warn("baselining output file\n");
	WRITE_FILE($exp_file, $output);
}

TRACE($output);
ASSERT(EQUALS_FILE($output, $exp_file), '... produces Xhtml output');

