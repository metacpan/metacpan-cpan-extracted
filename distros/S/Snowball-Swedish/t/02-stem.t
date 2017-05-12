#!/usr/local/bin/perl
use strict;
use warnings;
# $Id: 02-stem.t,v 1.1 2007/05/07 12:00:55 ask Exp $
# $Source: /opt/CVS/SeSnowball/t/02-stem.t,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1 $
# $Date: 2007/05/07 12:00:55 $
use vars qw($VERSION);
$VERSION = 1.2;

my $THIS_TEST_HAS_TESTS = 30_625;
my $DEBUG = 1;

use Test::More;
use Carp;
    plan(tests => $THIS_TEST_HAS_TESTS);
use_ok('Lingua::Stem::Snowball::Se');
use English qw( -no_match_vars );
use Lingua::Stem::Snowball::Se;
use FileHandle;
use FindBin;
my $stemmer = Lingua::Stem::Snowball::Se->new(use_cache => 0);

ok(1, 'Create new Snowball::Se object'); # If we made it this far, we're ok.
warn "Testing stemmer against database, this will take some time\n";

my $bin_dir    = $FindBin::Bin;
my $diffs_file = "$bin_dir/diffs.txt";
my $diffs_fh = FileHandle->new();
open $diffs_fh, "<$diffs_file" or die "Couldn't open $diffs_file: $OS_ERROR\n";

while (my $line = <$diffs_fh>) {
	chomp $line;
	my($orig, $result) = split m/\s+/xms, $line;
	my $stemmed = $stemmer->stem($orig);
	is($stemmed, $result, "$orig, $stemmed cmp $result");
}

close $diffs_fh or croak "Couldn't close $diffs_file: $OS_ERROR";

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

