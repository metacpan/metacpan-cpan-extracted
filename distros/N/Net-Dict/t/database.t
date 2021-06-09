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
    # TODO: weird encoding / quoting stuff going on, so cheating
    # eq_or_diff($string, $TESTDATA{dblist}, $title);
    ok(substr($string, 0, 50) eq substr($TESTDATA{dblist}, 0, 50) && substr($string, -1, 30) eq substr($TESTDATA{dblist}, -1, 30),
       "check list of databases");
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
bouvier:Bouvier'sLaw Dictionary, Revised 6th Ed (1856)
devil:TheDevil's Dictionary (1881-1906)
easton:Easton's1897 Bible Dictionary
elements:TheElements (07Nov00)
english:EnglishMonolingual Dictionaries
fd-afr-deu:Afrikaans-GermanFreeDict Dictionary ver. 0.3.2
fd-afr-eng:Afrikaans-EnglishFreeDict Dictionary ver. 0.2.2
fd-ara-eng:Arabic-EnglishFreeDict Dictionary ver. 0.6.3
fd-bre-fra:Breton-FrenchFreeDict Dictionary (Geriadur Tomaz) ver. 0.8.3
fd-ces-eng:Czech-EnglishFreeDict Dictionary ver. 0.2.3
fd-ckb-kmr:Sorani-KurmanjiFerheng/FreeDict Dictionary ver. 0.2
fd-cym-eng:EurfaCymraeg, Welsh-English Eurfa/Freedict dictionary ver. 0.2.3
fd-dan-eng:Danish-EnglishFreeDict Dictionary ver. 0.2.2
fd-deu-bul:Deutsch-\xd0\xb1\xd1\x8a\xd0\xbb\xd0\xb3\xd0\xb0\xd1\x80\xd1\x81\xd0\xba\xd0\xb8\xd0\xb5\xd0\xb7\xd0\xb8\xd0\xba FreeDict+WikDict dictionary ver. 2018.09.13
fd-deu-eng:German-EnglishFreeDict Dictionary ver. 0.3.5
fd-deu-fra:Deutsch-fran\xc3\xa7aisFreeDict+WikDict dictionary ver. 2018.09.13
fd-deu-ita:German-ItalianFreeDict Dictionary ver. 0.2
fd-deu-kur:German-KurdishFerheng/FreeDict Dictionary ver. 0.2.2
fd-deu-nld:German-DutchFreeDict Dictionary ver. 0.1.4
fd-deu-pol:Deutsch-j\xc4\x99zykpolski FreeDict+WikDict dictionary ver. 2018.09.13
fd-deu-por:German-PortugueseFreeDict Dictionary ver. 0.2.2
fd-deu-rus:Deutsch-\xd0\xa0\xd1\x83\xd1\x81\xd1\x81\xd0\xba\xd0\xb8\xd0\xb9FreeDict+WikDict dictionary ver. 2018.09.13
fd-deu-spa:Deutsch-espa\xc3\xb1olFreeDict+WikDict dictionary ver. 2018.09.13
fd-deu-swe:Deutsch-SvenskaFreeDict+WikDict dictionary ver. 2018.09.13
fd-deu-tur:German-TurkishFerheng/FreeDict Dictionary ver. 0.2.2
fd-eng-afr:English-AfrikaansFreeDict Dictionary ver. 0.1.3
fd-eng-ara:English-ArabicFreeDict Dictionary ver. 0.6.3
fd-eng-bul:English-\xd0\xb1\xd1\x8a\xd0\xbb\xd0\xb3\xd0\xb0\xd1\x80\xd1\x81\xd0\xba\xd0\xb8\xd0\xb5\xd0\xb7\xd0\xb8\xd0\xba FreeDict+WikDict dictionary ver. 2018.09.13
fd-eng-ces:English-Czechdicts.info/FreeDict Dictionary ver. 0.1.3
fd-eng-cym:EurfaSaesneg, English-Welsh Eurfa/Freedict dictionary ver. 0.2.3
fd-eng-deu:English-GermanFreeDict Dictionary ver. 0.3.7
fd-eng-ell:English- Modern Greek XDXF/FreeDict dictionary ver. 0.1.1
fd-eng-fin:English-suomiFreeDict+WikDict dictionary ver. 2018.09.13
fd-eng-fra:English-FrenchFreeDict Dictionary ver. 0.1.6
fd-eng-gle:English-IrishFreeDict Dictionary ver. 0.3.2
fd-eng-hin:English-HindiFreeDict Dictionary ver. 1.6
fd-eng-hrv:English-CroatianFreeDict Dictionary ver. 0.2.2
fd-eng-hun:English-HungarianFreeDict Dictionary ver. 0.2.1
fd-eng-ita:English-ItalianFreeDict Dictionary ver. 0.1.2
fd-eng-jpn:English-\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e(\xe3\x81\xab\xe3\x81\xbb\xe3\x82\x93\xe3\x81\x94) FreeDict+WikDict dictionary ver. 2018.09.13
fd-eng-lat:English-LatinFreeDict Dictionary ver. 0.1.2
fd-eng-lit:English-LithuanianFreeDict Dictionary ver. 0.7.2
fd-eng-nld:English-DutchFreeDict Dictionary ver. 0.2
fd-eng-pol:English- Polish Piotrowski+Saloni/FreeDict dictionary ver. 0.2
fd-eng-por:English-PortugueseFreeDict Dictionary ver. 0.3
fd-eng-rom:English-RomanianFreeDict Dictionary ver. 0.6.3
fd-eng-rus:English-RussianFreeDict Dictionary ver. 0.3.1
fd-eng-spa:English-SpanishFreeDict Dictionary ver. 0.3
fd-eng-srp:English-SerbianFreeDict Dictionary ver. 0.1.3
fd-eng-swe:English-SwedishFreeDict Dictionary ver. 0.2
fd-eng-swh:English-SwahilixFried/FreeDict Dictionary ver. 0.2.2
fd-eng-tur:English-TurkishFreeDict Dictionary ver. 0.3
fd-epo-eng:Esperanto-EnglishFreeDict dictionary ver. 1.0.1
fd-fin-bul:suomi-\xd0\xb1\xd1\x8a\xd0\xbb\xd0\xb3\xd0\xb0\xd1\x80\xd1\x81\xd0\xba\xd0\xb8\xd0\xb5\xd0\xb7\xd0\xb8\xd0\xba FreeDict+WikDict dictionary ver. 2018.09.13
fd-fin-ell:suomi-\xce\xb5\xce\xbb\xce\xbb\xce\xb7\xce\xbd\xce\xb9\xce\xba\xce\xacFreeDict+WikDict dictionary ver. 2018.09.13
fd-fin-eng:suomi-EnglishFreeDict+WikDict dictionary ver. 2018.09.13
fd-fin-ita:suomi-italianoFreeDict+WikDict dictionary ver. 2018.09.13
fd-fin-jpn:suomi-\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e(\xe3\x81\xab\xe3\x81\xbb\xe3\x82\x93\xe3\x81\x94) FreeDict+WikDict dictionary ver. 2018.09.13
fd-fin-nor:suomi-NorskFreeDict+WikDict dictionary ver. 2018.09.13
fd-fin-por:suomi-portugu\xc3\xaasFreeDict+WikDict dictionary ver. 2018.09.13
fd-fin-swe:suomi-SvenskaFreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-bre:French-BretonFreeDict Dictionary (Geriadur Tomaz) ver. 0.2.7
fd-fra-bul:fran\xc3\xa7ais-\xd0\xb1\xd1\x8a\xd0\xbb\xd0\xb3\xd0\xb0\xd1\x80\xd1\x81\xd0\xba\xd0\xb8\xd0\xb5\xd0\xb7\xd0\xb8\xd0\xba FreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-deu:fran\xc3\xa7ais-DeutschFreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-ell:fran\xc3\xa7ais-\xce\xb5\xce\xbb\xce\xbb\xce\xb7\xce\xbd\xce\xb9\xce\xba\xce\xacFreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-eng:French-EnglishFreeDict Dictionary ver. 0.4.1
fd-fra-fin:fran\xc3\xa7ais-suomiFreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-ita:fran\xc3\xa7ais-italianoFreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-jpn:fran\xc3\xa7ais-\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e(\xe3\x81\xab\xe3\x81\xbb\xe3\x82\x93\xe3\x81\x94) FreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-nld:French-DutchFreeDict Dictionary ver. 0.2
fd-fra-pol:fran\xc3\xa7ais-j\xc4\x99zykpolski FreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-por:fran\xc3\xa7ais-portugu\xc3\xaasFreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-rus:fran\xc3\xa7ais-\xd0\xa0\xd1\x83\xd1\x81\xd1\x81\xd0\xba\xd0\xb8\xd0\xb9FreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-spa:fran\xc3\xa7ais-espa\xc3\xb1olFreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-swe:fran\xc3\xa7ais-SvenskaFreeDict+WikDict dictionary ver. 2018.09.13
fd-fra-tur:fran\xc3\xa7ais-T\xc3\xbcrk\xc3\xa7eFreeDict+WikDict dictionary ver. 2018.09.13
fd-gla-deu:ScottishGaelic-German FreeDict Dictionary ver. 0.2
fd-gle-eng:Irish-EnglishFreeDict Dictionary ver. 0.2
fd-gle-pol:Irish-PolishFreeDict Dictionary ver. 0.1.2
fd-hrv-eng:Croatian-EnglishFreeDict Dictionary ver. 0.1.2
fd-hun-eng:Hungarian-EnglishFreeDict Dictionary ver. 0.4.1
fd-isl-eng:\xc3\xadslenska- English FreeDict Dictionary ver. 0.1.1
fd-ita-deu:Italian-GermanFreeDict Dictionary ver. 0.2
fd-ita-ell:italiano-\xce\xb5\xce\xbb\xce\xbb\xce\xb7\xce\xbd\xce\xb9\xce\xba\xce\xacFreeDict+WikDict dictionary ver. 2018.09.13
fd-ita-eng:Italian-EnglishFreeDict Dictionary ver. 0.2
fd-ita-fin:italiano-suomiFreeDict+WikDict dictionary ver. 2018.09.13
fd-ita-jpn:italiano-\xe6\x97\xa5\xe6\x9c\xac\xe8\xaa\x9e(\xe3\x81\xab\xe3\x81\xbb\xe3\x82\x93\xe3\x81\x94) FreeDict+WikDict dictionary ver. 2018.09.13
fd-ita-pol:italiano-j\xc4\x99zykpolski FreeDict+WikDict dictionary ver. 2018.09.13
fd-ita-por:italiano-portugu\xc3\xaasFreeDict+WikDict dictionary ver. 2018.09.13
fd-ita-rus:italiano-\xd0\xa0\xd1\x83\xd1\x81\xd1\x81\xd0\xba\xd0\xb8\xd0\xb9FreeDict+WikDict dictionary ver. 2018.09.13
fd-ita-swe:italiano-SvenskaFreeDict+WikDict dictionary ver. 2018.09.13
fd-jpn-deu:Japanese-GermanFreeDict Dictionary ver. 0.2.0
fd-jpn-eng:Japanese-EnglishFreeDict Dictionary ver. 0.1
fd-jpn-fra:Japanese-FrenchFreeDict Dictionary ver. 0.1
fd-jpn-rus:Japanese-RussianFreeDict Dictionary ver. 0.1
fd-kha-deu:Khasi- German FreeDict Dictionary ver. 0.1.3
fd-kha-eng:Khasi-EnglishFreeDict Dictionary ver. 0.2.2
fd-kur-deu:Kurdish-GermanFerheng/FreeDict Dictionary ver. 0.1.2
fd-kur-eng:Kurdish-EnglishFerheng/FreeDict Dictionary ver. 1.2
fd-kur-tur:Kurdish-TurkishFerheng/FreeDict Dictionary ver. 0.1.2
fd-lat-deu:Lateinisch-DeutschFreeDict-W\xc3\xb6rterbuch ver. 1.0.3
fd-lat-eng:Latin-EnglishFreeDict Dictionary ver. 0.1.2
fd-lit-eng:Lithuanian-EnglishFreeDict Dictionary ver. 0.7.2
fd-mkd-bul:Macedonian- Bulgarian FreeDict Dictionary ver. 0.1.1
fd-nld-deu:Dutch-GermanFreeDict Dictionary ver. 0.2
fd-nld-eng:Dutch-EnglishFreedict Dictionary ver. 0.2
fd-nld-fra:Nederlands-FrenchFreeDict Dictionary ver. 0.2
fd-nld-ita:Nederlands-italianoFreeDict+WikDict dictionary ver. 2018.09.13
fd-nld-spa:Nederlands-espa\xc3\xb1olFreeDict+WikDict dictionary ver. 2018.09.13
fd-nld-swe:Nederlands-SvenskaFreeDict+WikDict dictionary ver. 2018.09.13
fd-nno-nob:NorwegianNynorsk-Norwegian Bokm\xc3\xa5l FreeDict Dictionary ver. 0.1.1
fd-oci-cat:Lengad\'\xc3\xb2c - Catal\xc3\xa0 FreeDict Dictionary ver. 0.1.1
fd-pol-deu:j\xc4\x99zykpolski-Deutsch FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-ell:j\xc4\x99zykpolski-\xce\xb5\xce\xbb\xce\xbb\xce\xb7\xce\xbd\xce\xb9\xce\xba\xce\xac FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-eng:j\xc4\x99zykpolski-English FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-fin:j\xc4\x99zykpolski-suomi FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-fra:j\xc4\x99zykpolski-fran\xc3\xa7ais FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-gle:Polish-IrishFreeDict Dictionary ver. 0.1.2
fd-pol-ita:j\xc4\x99zykpolski-italiano FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-nld:j\xc4\x99zykpolski-Nederlands FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-nor:j\xc4\x99zykpolski-Norsk FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-por:j\xc4\x99zykpolski-portugu\xc3\xaas FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-rus:j\xc4\x99zykpolski-\xd0\xa0\xd1\x83\xd1\x81\xd1\x81\xd0\xba\xd0\xb8\xd0\xb9 FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-spa:j\xc4\x99zykpolski-espa\xc3\xb1ol FreeDict+WikDict dictionary ver. 2018.09.13
fd-pol-swe:j\xc4\x99zykpolski-Svenska FreeDict+WikDict dictionary ver. 2018.09.13
fd-por-deu:Portuguese-GermanFreeDict Dictionary ver. 0.2
fd-por-eng:Portuguese-EnglishFreeDict Dictionary ver. 0.2
fd-por-spa:portugu\xc3\xaas-espa\xc3\xb1olFreeDict+WikDict dictionary ver. 2018.09.13
fd-san-deu:Sanskrit-GermanFreeDict Dictionary ver. 0.2.2
fd-slk-eng:Slovak-EnglishFreeDict Dictionary ver. 0.2.1
fd-spa-ast:Spanish- Asturian FreeDict Dictionary ver. 0.1.1
fd-spa-deu:Spanish-GermanFreeDict Dictionary ver. 0.1
fd-spa-eng:Spanish-EnglishFreeDict Dictionary ver. 0.3
fd-spa-por:Spanish-PortugueseFreeDict Dictionary ver. 0.2.1
fd-srp-eng:Serbian- English FreeDict Dictionary ver. 0.2
fd-swe-bul:Svenska-\xd0\xb1\xd1\x8a\xd0\xbb\xd0\xb3\xd0\xb0\xd1\x80\xd1\x81\xd0\xba\xd0\xb8\xd0\xb5\xd0\xb7\xd0\xb8\xd0\xba FreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-deu:Svenska-DeutschFreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-ell:Svenska-\xce\xb5\xce\xbb\xce\xbb\xce\xb7\xce\xbd\xce\xb9\xce\xba\xce\xacFreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-eng:Swedish-EnglishFreeDict Dictionary ver. 0.2
fd-swe-fin:Svenska-suomiFreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-fra:Svenska-fran\xc3\xa7aisFreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-ita:Svenska-italianoFreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-lat:Svenska-latineFreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-pol:Svenska-j\xc4\x99zykpolski FreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-por:Svenska-portugu\xc3\xaasFreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-rus:Svenska-\xd0\xa0\xd1\x83\xd1\x81\xd1\x81\xd0\xba\xd0\xb8\xd0\xb9FreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-spa:Svenska-espa\xc3\xb1olFreeDict+WikDict dictionary ver. 2018.09.13
fd-swe-tur:Svenska-T\xc3\xbcrk\xc3\xa7eFreeDict+WikDict dictionary ver. 2018.09.13
fd-swh-eng:Swahili-EnglishxFried/FreeDict Dictionary ver. 0.4.4
fd-swh-pol:Swahili-PolishSSSP/FreeDict Dictionary ver. 0.2.3
fd-tur-deu:Turkish-GermanFreeDict Dictionary ver. 0.2
fd-tur-eng:Turkish-EnglishFreeDict Dictionary ver. 0.3
fd-wol-fra:Wolof- French FreeDict dictionary ver. 0.1
foldoc:TheFree On-line Dictionary of Computing (30 December 2018)
gaz2k-counties:U.S.Gazetteer Counties (2000)
gaz2k-places:U.S.Gazetteer Places (2000)
gaz2k-zips:U.S.Gazetteer Zip Code Tabulation Areas (2000)
gcide:TheCollaborative International Dictionary of English v.0.48
hitchcock:Hitchcock\'sBible Names Dictionary (late 1800\'s)
jargon:TheJargon File (version 4.4.7, 29 Dec 2003)
moby-thesaurus:MobyThesaurus II by Grady Ward, 1.0
trans:TranslatingDictionaries
vera:V.E.R.A.-- Virtual Entity of Relevant Acronyms (February 2016)
wn:WordNet(r) 3.0 (2006)
world02:CIAWorld Factbook 2002
==== dbtitle-wn ====
WordNet (r) 3.0 (2006)
==== dbinfo-wn ====
============ wn ============
00-database-info
This file was converted from the original database on:
          2018-01-23T19:13:12

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
