#!./perl
#
# database.t - Net::Dict testsuite for database related methods
#

use Test::More 0.88;
use Test::RequiresInternet 0.05 ('dict.org' => 2628);
use Test::Differences qw/ eq_or_diff /;
use Net::Dict;
use lib 't/lib';
use Net::Dict::TestConfig qw/ $TEST_HOST $TEST_PORT /;

$^W = 1;

my $WARNING;
my %TESTDATA;
my $section;
my $string;
my $dbinfo;
my $title;

plan tests => 13;

$SIG{__WARN__} = sub { $WARNING = join('', @_); };

#-----------------------------------------------------------------------
# Build the hash of test data from after the __DATA__ symbol
# at the end of this file
#-----------------------------------------------------------------------
while (<DATA>) {
    if (/^==== END ====$/) {
        $section = undef;
        next;
    }

    if (/^==== (\S+) ====$/) {
        $section = $1;
        $TESTDATA{$section} = '';
        next;
    }

    next unless defined $section;

    $TESTDATA{$section} .= $_;
}

#-----------------------------------------------------------------------
# Make sure we have HOST and PORT specified
#-----------------------------------------------------------------------
ok(defined($TEST_HOST) && defined($TEST_PORT),
   "Do we have a test host and port?");

#-----------------------------------------------------------------------
# connect to server
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($TEST_HOST, Port => $TEST_PORT); };
ok(!$@ && defined $dict, "Connect to DICT server");

#-----------------------------------------------------------------------
# call dbs() with an argument - it doesn't take any, and should die
#-----------------------------------------------------------------------
eval { %dbhash = $dict->dbs('foo'); };
ok($@ && $@ =~ /takes no arguments/, "dbs() with an argument should croak");

#-----------------------------------------------------------------------
# pass a hostname of empty string, should get undef back
#-----------------------------------------------------------------------
$string = '';
$title  = "Check list of database names";
eval { %dbhash = $dict->dbs(); };
if (!$@
    && %dbhash
    && do { foreach my $db (sort keys %dbhash) { $string .= "${db}:$dbhash{$db}\n"; }; 1; })
{
    eq_or_diff($string, $TESTDATA{dblist}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# call dbInfo() method with no arguments
#-----------------------------------------------------------------------
$dbinfo = undef;
eval { $dbinfo = $dict->dbInfo(); };
ok($@ && $@ =~ /one argument only/, "dbInfo() with no arguments should croak");

#-----------------------------------------------------------------------
# call dbInfo() method with more than one argument
#-----------------------------------------------------------------------
$dbinfo = undef;
eval { $dbinfo = $dict->dbInfo('wn', 'web1913'); };
ok($@ && $@ =~ /one argument only/, "dbInfo() with more than one argument should croak");

#-----------------------------------------------------------------------
# call dbInfo() method with one argument, but it's a non-existent DB
#-----------------------------------------------------------------------
$dbinfo = undef;
eval { $dbinfo = $dict->dbInfo('web1651'); };
ok(!$@ && !defined($dbinfo), "dbInfo() on a non-existent DB should return undef");

#-----------------------------------------------------------------------
# get the database info for the wordnet db, and compare with expected
#-----------------------------------------------------------------------
$string = '';
$dbinfo = undef;
$title  = "Do we get expected DB info for wordnet?";
eval { $dbinfo = $dict->dbInfo('wn'); };
if (!$@
    && defined($dbinfo))
{
    eq_or_diff($dbinfo, $TESTDATA{'dbinfo-wn'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with no arguments - should result in die()
#-----------------------------------------------------------------------
eval { $string = $dict->dbTitle(); };
ok($@ && $@ =~ /method expects one argument/, "dbTitle() with no arguments should croak");

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with too many arguments - should result in die()
#-----------------------------------------------------------------------
eval { $string = $dict->dbTitle('wn', 'foldoc'); };
ok($@ && $@ =~ /method expects one argument/, "dbTitle() with more than one argument should croak");

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with non-existent DB - should result in undef
#-----------------------------------------------------------------------
$WARNING = '';
eval { $string = $dict->dbTitle('web1651'); };
ok(!$@ && !defined($string), "dbTitle() on a non-existent DB should return undef");

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with non-existent DB - should result in undef
# We set debug level to 1, should result in a warning message as
# well as undef. The Net::Cmd::debug() line is needed to suppress
# some verbosity from Net::Cmd when we turn on debugging.
# This is done so that the "make test" *looks* clean as well as being clean.
#-----------------------------------------------------------------------
Net::Dict->debug(0);
$dict->debug(1);
$WARNING = '';
eval { $string = $dict->dbTitle('web1651'); };
ok(!$@ && !defined($string) && $WARNING =~ /unknown database/,
   "dbTitle on a non-existent database name should return undef");
$dict->debug(0);

#-----------------------------------------------------------------------
# METHOD: dbTitle
# Call method with an OK DB name
#-----------------------------------------------------------------------
$title = "check dbTitle() on wordnet";
eval { $string = $dict->dbTitle('wn'); };
if (!$@ && defined($string)) {
    eq_or_diff($string."\n", $TESTDATA{'dbtitle-wn'}, $title);
}
else {
    fail($title);
}

exit 0;

__DATA__
==== dblist ====
all:All Dictionaries (English-Only and Translating)
bouvier:Bouvier's Law Dictionary, Revised 6th Ed (1856)
devil:The Devil's Dictionary (1881-1906)
easton:Easton's 1897 Bible Dictionary
elements:The Elements (07Nov00)
english:English Monolingual Dictionaries
fd-afr-deu:Afrikaans-German FreeDict Dictionary ver. 0.3
fd-cro-eng:Croatian-English Freedict Dictionary
fd-cze-eng:Czech-English Freedict dictionary
fd-dan-eng:Danish-English FreeDict Dictionary ver. 0.2.1
fd-deu-eng:German-English FreeDict Dictionary ver. 0.3.4
fd-deu-fra:German-French FreeDict Dictionary ver. 0.3.1
fd-deu-ita:German-Italian FreeDict Dictionary ver. 0.1.1
fd-deu-nld:German-Dutch FreeDict Dictionary ver. 0.1.1
fd-deu-por:German-Portuguese FreeDict Dictionary ver. 0.2.1
fd-eng-ara:English-Arabic FreeDict Dictionary ver. 0.6.2
fd-eng-cro:English-Croatian Freedict Dictionary
fd-eng-cze:English-Czech fdicts/FreeDict Dictionary
fd-eng-deu:English-German FreeDict Dictionary ver. 0.3.6
fd-eng-fra:English-French FreeDict Dictionary ver. 0.1.4
fd-eng-hin:English-Hindi FreeDict Dictionary ver. 1.5.1
fd-eng-hun:English-Hungarian FreeDict Dictionary ver. 0.1
fd-eng-iri:English-Irish Freedict dictionary
fd-eng-ita:English-Italian FreeDict Dictionary ver. 0.1.1
fd-eng-lat:English-Latin FreeDict Dictionary ver. 0.1.1
fd-eng-nld:English-Dutch FreeDict Dictionary ver. 0.1.1
fd-eng-por:English-Portuguese FreeDict Dictionary ver. 0.2.2
fd-eng-rom:English-Romanian FreeDict Dictionary ver. 0.6.1
fd-eng-rus:English-Russian FreeDict Dictionary ver. 0.3
fd-eng-scr:English-Serbo-Croat Freedict dictionary
fd-eng-spa:English-Spanish FreeDict Dictionary ver. 0.2.1
fd-eng-swa:English-Swahili xFried/FreeDict Dictionary
fd-eng-swe:English-Swedish FreeDict Dictionary ver. 0.1.1
fd-eng-tur:English-Turkish FreeDict Dictionary ver. 0.2.1
fd-eng-wel:English-Welsh Freedict dictionary
fd-fra-deu:French-German FreeDict Dictionary ver. 0.1.1
fd-fra-eng:French-English FreeDict Dictionary ver. 0.3.4
fd-fra-nld:French-Dutch FreeDict Dictionary ver. 0.1.2
fd-gla-deu:Scottish Gaelic-German FreeDict Dictionary ver. 0.1.1
fd-hin-eng:English-Hindi Freedict Dictionary [reverse index]
fd-hun-eng:Hungarian-English FreeDict Dictionary ver. 0.3.1
fd-iri-eng:Irish-English Freedict dictionary
fd-ita-deu:Italian-German FreeDict Dictionary ver. 0.1.1
fd-ita-eng:Italian-English FreeDict Dictionary ver. 0.1.1
fd-jpn-deu:Japanese-German FreeDict Dictionary ver. 0.1.1
fd-lat-deu:Latin - German FreeDict dictionary ver. 0.4
fd-lat-eng:Latin-English FreeDict Dictionary ver. 0.1.1
fd-nld-deu:Dutch-German FreeDict Dictionary ver. 0.1.1
fd-nld-eng:Dutch-English Freedict Dictionary ver. 0.1.3
fd-nld-fra:Nederlands-French FreeDict Dictionary ver. 0.1.1
fd-por-deu:Portuguese-German FreeDict Dictionary ver. 0.1.1
fd-por-eng:Portuguese-English FreeDict Dictionary ver. 0.1.1
fd-scr-eng:Serbo-Croat-English Freedict dictionary
fd-slo-eng:Slovak-English Freedict dictionary
fd-spa-eng:Spanish-English FreeDict Dictionary ver. 0.1.1
fd-swa-eng:Swahili-English xFried/FreeDict Dictionary
fd-swe-eng:Swedish-English FreeDict Dictionary ver. 0.1.1
fd-tur-deu:Turkish-German FreeDict Dictionary ver. 0.1.1
fd-tur-eng:Turkish-English FreeDict Dictionary ver. 0.2.1
fd-wel-eng:Welsh-English Freedict dictionary
foldoc:The Free On-line Dictionary of Computing (18 March 2015)
gaz2k-counties:U.S. Gazetteer Counties (2000)
gaz2k-places:U.S. Gazetteer Places (2000)
gaz2k-zips:U.S. Gazetteer Zip Code Tabulation Areas (2000)
gcide:The Collaborative International Dictionary of English v.0.48
hitchcock:Hitchcock's Bible Names Dictionary (late 1800's)
jargon:The Jargon File (version 4.4.7, 29 Dec 2003)
moby-thesaurus:Moby Thesaurus II by Grady Ward, 1.0
trans:Translating Dictionaries
vera:V.E.R.A. -- Virtual Entity of Relevant Acronyms (September 2014)
wn:WordNet (r) 3.0 (2006)
world02:CIA World Factbook 2002
==== dbtitle-wn ====
WordNet (r) 3.0 (2006)
==== dbinfo-wn ====
============ wn ============
00-database-info
This file was converted from the original database on:
          2014-04-17T12:33:52

The original data is available from:
     ftp://ftp.cogsci.princeton.edu/pub/wordnet/2.0

The original data was distributed with the notice shown below. No
additional restrictions are claimed.  Please redistribute this changed
version under the same conditions and restriction that apply to the
original version.


This software and database is being provided to you, the LICENSEE, by  
Princeton University under the following license.  By obtaining, using  
and/or copying this software and database, you agree that you have  
read, understood, and will comply with these terms and conditions.:  

Permission to use, copy, modify and distribute this software and  
database and its documentation for any purpose and without fee or  
royalty is hereby granted, provided that you agree to comply with  
the following copyright notice and statements, including the disclaimer,  
and that the same appear on ALL copies of the software, database and  
documentation, including modifications that you make for internal  
use or for distribution.  

WordNet 3.0 Copyright 2006 by Princeton University.  All rights reserved.  

THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND PRINCETON  
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR  
IMPLIED.  BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON  
UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES OF MERCHANT-  
ABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE OR THAT THE USE  
OF THE LICENSED SOFTWARE, DATABASE OR DOCUMENTATION WILL NOT  
INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS, TRADEMARKS OR  
OTHER RIGHTS.  

The name of Princeton University or Princeton may not be used in  
advertising or publicity pertaining to distribution of the software  
and/or database.  Title to copyright in this software, database and  
any associated documentation shall at all times remain with  
Princeton University and LICENSEE agrees to preserve same.  


==== END ====
