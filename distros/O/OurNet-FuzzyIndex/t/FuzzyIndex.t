#!/usr/bin/perl -w

use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 9 }

# Load BBS
use OurNet::FuzzyIndex;

my $idxfile  = 'test.idx'; # Name of the database file
my $pagesize = undef;      # Page size (twice of an average record)
my $cache    = undef;      # Cache size (undef to use default)
my $subdbs   = 0;          # Number of child dbs; 0 for none

# Initiate the DB from scratch
unlink $idxfile if -e $idxfile;
my $db = OurNet::FuzzyIndex->new($idxfile, $pagesize, $cache, $subdbs);

ok($db);

# Index a record: key = 'Doc1', content = 'Some text here'
$db->insert('800', 'Some text here');
ok($db->{idxcount}, 1);

# Alternatively, parse the content first with different weights
my %words = $db->parse_xs("Some other text here", 5);
%words = $db->parse_xs("Some more texts here", 2, \%words);

# ok($words{'some  '}, 7); # could fail. deprecated anyway.

# Then index the resulting hash with 'Doc2' as its key
$db->insert('300', %words);
ok($db->{idxcount}, 2);

# Perform a query: the 2nd argument is the 'exact match' flag
my %result = $db->query('search for some text', $MATCH_FUZZY);

if ($[ < 5.006) {
    ok(1) for (1..4); # XXX todo
}
else {
    ok(scalar keys(%result), 2);

    # Dump the results; note you have to call $db->getkey each time
    foreach my $idx (sort {$result{$b} <=> $result{$a}} keys(%result)) {
	ok($result{$idx}, $db->getkey($idx));
    }
}

# Set database variables
$db->setvar('variable', "fetch success!\n");
ok($db->getvar('variable'), "fetch success!\n");

# Alternatively, get it with its internal index number
my %allkeys = $db->getkeys(1);

ok($allkeys{"\x00\x00\x00\x01"}, 800);

undef $db;
unlink('test.idx');
