#!./perl
#
# match.t - Net::Dict testsuite for match() method
#

use Test::More 0.88;
use Test::RequiresInternet 0.05 ('dict.org' => 2628);
use Test::Differences qw/ eq_or_diff /;
use Net::Dict;
use lib 't/lib';
use Net::Dict::TestConfig qw/ $TEST_HOST $TEST_PORT /;
use Env qw($VERBOSE);

$^W = 1;

my $WARNING;
my %TESTDATA;
my $defref;
my $section;
my $string;
my $dbinfo;
my %strathash;
my $title;

plan tests => 15;

if (defined $VERBOSE && $VERBOSE==1) {
    print STDERR "\nVERBOSE ON\n";
}

$SIG{__WARN__} = sub { $WARNING = join('', @_); };

#-----------------------------------------------------------------------
# Build the hash of test data from after the __DATA__ symbol
# at the end of this file
#-----------------------------------------------------------------------
while (<DATA>)
{
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
   "Do we have a test HOST and PORT?");

#-----------------------------------------------------------------------
# connect to server
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($TEST_HOST, Port => $TEST_PORT); };
ok(!$@ && defined($dict), "connect to DICT server");

#-----------------------------------------------------------------------
# call match() with no arguments - should die
#-----------------------------------------------------------------------
eval { $defref = $dict->match(); };
ok($@ && $@ =~ /takes at least two arguments/,
   "calling match() with no arguments should croak()");

#-----------------------------------------------------------------------
# call match() with one arguments - should die
#-----------------------------------------------------------------------
eval { $defref = $dict->match('banana'); };
ok($@ && $@ =~ /takes at least two arguments/,
   "match() with no argument should croak");

#-----------------------------------------------------------------------
# call match() with two arguments, but word is undef
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->match(undef, '*'); };
ok(!$@ && !defined($defref)
    && $WARNING =~ /empty pattern passed to match/,
   "match() with 2 arguments, but word is undef, should return undef");

#-----------------------------------------------------------------------
# call match() with two arguments, but word is empty string
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->match('', '*'); };
ok(!$@
    && !defined($defref)
    && $WARNING =~ /empty pattern passed to match/,
   "match() with 2 args but empty word should return undef");

#-----------------------------------------------------------------------
# get a list of supported strategies, render as string and compare
#-----------------------------------------------------------------------
$title  = "do we get the expected list of strategies";
$string = '';
eval { %strathash = $dict->strategies(); };
if (!$@
    && %strathash
    && do {
        foreach my $s (sort keys %strathash)
        {
            $string .= $s.':'.$strathash{$s}."\n";
        }
        1;
    })
{
    eq_or_diff($string, $TESTDATA{'strats'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# same as previous test, but using obsolete method name
#-----------------------------------------------------------------------
$title  = "do we get the expected list of strats (back compat)";
$string = '';
eval { %strathash = $dict->strats(); };
if (!$@
    && %strathash
    && do {
        foreach my $s (sort keys %strathash)
        {
            $string .= $s.':'.$strathash{$s}."\n";
        }
        1;
    })
{
    eq_or_diff($string, $TESTDATA{'strats'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# A list of words which start with "blue screen" - ie contains
# a space.
#-----------------------------------------------------------------------
$title = "get a list of words starting with 'blue screen'";
eval { $defref = $dict->match('blue screen', 'prefix', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); })
{
    eq_or_diff($string, $TESTDATA{'*-prefix-blue_screen'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# A list of words which start with "blue " in the jargon dictionary.
# We've previously specified a default dictionary of foldoc,
# but we shouldn't get anything from that.
#-----------------------------------------------------------------------
$title = "list of words starting with 'blue ' in the jargon dict";
$dict->setDicts('foldoc');
eval { $defref = $dict->match('blue ', 'prefix', 'jargon'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); })
{
    eq_or_diff($string, $TESTDATA{'jargon-prefix-blue_'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: match
# Now we do the same match, but without specifying a dictionary,
# so it should fall back on the previously specified foldoc
#-----------------------------------------------------------------------
$title = "match words starting with 'blue '";
$dict->setDicts('foldoc');
eval { $defref = $dict->match('blue ', 'prefix'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); })
{
    eq_or_diff($string, $TESTDATA{'foldoc-prefix-blue_'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: match
# Look for words with apostrophe in them, in a specific dictionary
#-----------------------------------------------------------------------
$title = "use match() to look for words with an apostophe, in world02";
eval { $defref = $dict->match("d'i", 're', 'world02'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); })
{
    eq_or_diff($string, $TESTDATA{"world02-re-'"}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: match
# look for all words in all dictionaries ending in "standard"
#-----------------------------------------------------------------------
$title = "look for words ending in 'standard' in all DBs";
eval { $defref = $dict->match("standard", 'suffix', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); })
{
    eq_or_diff($string, $TESTDATA{'*-suffix-standard'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: match
# Using regular expressions to find all entries in a dictionary
# of a given length
#-----------------------------------------------------------------------
$title = "use regexp to find all entries of a given length";
eval { $defref = $dict->match('^a....................$',
                              're', 'wn'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); })
{
    eq_or_diff($string, $TESTDATA{'web1913-re-dotmatch'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: match
# Look for words which have a Levenshtein distance one
# from "know"
#-----------------------------------------------------------------------
$title = "look for words with a Levenshtein distance one from 'know'";
eval { $defref = $dict->match('know', 'lev', '*'); };
if (!$@
    && defined $defref
    && do { $string = _format_matches($defref); })
{
    eq_or_diff($string, $TESTDATA{'*-lev-know'}, $title);
}
else {
    fail($title);
}


exit 0;

#=======================================================================
#
# _format_matches()
#
# takes a reference to a list which is assumed to be the result
# from a match() - each entry in the list is a reference to
# a 2-element list: [DICTIONARY, WORD]
#
# We return a string which has one line per entry:
#        DICTIONARY:WORD
# sorted on the whole line (ie by dictionary, then by word)
#
#=======================================================================
sub _format_matches
{
    my $mref  = shift;

    my $string = '';


    foreach my $entry (sort { lc($a->[0].$a->[1]) cmp lc($b->[0].$b->[1]) } @$mref)
    {
        $string .= $entry->[0].':'.$entry->[1]."\n";
    }

    return $string;
}

__DATA__
==== strats ====
exact:Match headwords exactly
first:Match the first word within headwords
last:Match the last word within headwords
lev:Match headwords within Levenshtein distance one
nprefix:Match prefixes (skip, count)
prefix:Match prefixes
re:POSIX 1003.2 (modern) regular expressions
regexp:Old (basic) regular expressions
soundex:Match using SOUNDEX algorithm
substring:Match substring occurring anywhere in a headword
suffix:Match suffixes
word:Match separate words within headwords
==== *-exact-blue ====
easton:Blue
foldoc:Blue
gazetteer:Blue
web1913:Blue
web1913:blue
wn:blue
==== *-prefix-blue_screen ====
foldoc:blue screen of death
foldoc:blue screen of life
jargon:blue screen of death
==== jargon-prefix-blue_ ====
jargon:blue box
jargon:blue glue
jargon:blue goo
jargon:blue screen of death
jargon:blue wire
==== foldoc-prefix-blue_ ====
foldoc:blue book
foldoc:blue box
foldoc:blue dot syndrome
foldoc:blue glue
foldoc:blue screen of death
foldoc:blue screen of life
foldoc:blue sky software
foldoc:blue wire
==== world02-re-' ====
world02:Cote d'Ivoire
==== *-suffix-standard ====
bouvier:STANDARD
foldoc:a tools integration standard
foldoc:advanced encryption standard
foldoc:american national standard
foldoc:binary compatibility standard
foldoc:data encryption standard
foldoc:de facto standard
foldoc:digital signature standard
foldoc:display standard
foldoc:filesystem hierarchy standard
foldoc:ieee floating point standard
foldoc:international standard
foldoc:object compatibility standard
foldoc:recommended standard
foldoc:robot exclusion standard
foldoc:standard
foldoc:video display standard
gaz2k-places:Standard
gcide:deficient inferior substandard
gcide:Double standard
gcide:double standard
gcide:non-standard
gcide:nonstandard
gcide:standard
gcide:Standard
jargon:ansi standard
moby-thesaurus:standard
wn:accounting standard
wn:double standard
wn:gold standard
wn:monetary standard
wn:nonstandard
wn:procrustean standard
wn:silver standard
wn:standard
wn:substandard
==== web1913-re-dotmatch ====
wn:aaron montgomery ward
wn:abelmoschus moschatus
wn:aboriginal australian
wn:abruptly-pinnate leaf
wn:absence without leave
wn:acacia auriculiformis
wn:acid-base equilibrium
wn:acquisition agreement
wn:acute-angled triangle
wn:adams-stokes syndrome
wn:adenosine diphosphate
wn:adlai ewing stevenson
wn:advance death benefit
wn:aeronautical engineer
wn:affine transformation
wn:africanized honey bee
wn:ageratum houstonianum
wn:aglaomorpha meyeniana
wn:agnes george de mille
wn:agnes gonxha bojaxhiu
wn:agricultural labourer
wn:agriculture secretary
wn:agrippina the younger
wn:agropyron intermedium
wn:agropyron pauciflorum
wn:agropyron subsecundum
wn:air-to-ground missile
wn:airborne transmission
wn:aksa martyrs brigades
wn:albatrellus dispansus
wn:alben william barkley
wn:aldous leonard huxley
wn:aldrovanda vesiculosa
wn:alex boncayao brigade
wn:alexander archipelago
wn:alexander graham bell
wn:alexis de tocqueville
wn:alfred alistair cooke
wn:alfred bernhard nobel
wn:alfred charles kinsey
wn:alfred edward housman
wn:alfred lothar wegener
wn:alfred russel wallace
wn:alkylbenzenesulfonate
wn:allied command europe
wn:allium cepa viviparum
wn:amaranthus graecizans
wn:ambloplites rupestris
wn:ambrosia psilostachya
wn:ambystomid salamander
wn:amelanchier alnifolia
wn:american bog asphodel
wn:american mountain ash
wn:american parsley fern
wn:american pasqueflower
wn:american red squirrel
wn:american saddle horse
wn:amphitheatrum flavium
wn:amsinckia grandiflora
wn:andrew william mellon
wn:andropogon virginicus
wn:anemopsis californica
wn:angelica archangelica
wn:angolan monetary unit
wn:anogramma leptophylla
wn:anointing of the sick
wn:anterior crural nerve
wn:anterior jugular vein
wn:anterior labial veins
wn:anthriscus sylvestris
wn:anthyllis barba-jovis
wn:anti-racketeering law
wn:anti-submarine rocket
wn:anti-takeover defense
wn:antiballistic missile
wn:antigenic determinant
wn:antihemophilic factor
wn:antihypertensive drug
wn:antilocapra americana
wn:antiophthalmic factor
wn:antitrust legislation
wn:anton van leeuwenhoek
wn:antonio lucio vivaldi
wn:antonius stradivarius
wn:apalachicola rosemary
wn:apex of the sun's way
wn:aposematic coloration
wn:appalachian mountains
wn:appendicular skeleton
wn:arceuthobium pusillum
wn:archeological remains
wn:archimedes' principle
wn:arctostaphylos alpina
wn:ardisia escallonoides
wn:arenaria groenlandica
wn:ariocarpus fissuratus
wn:army of the righteous
wn:arna wendell bontemps
wn:arnold joseph toynbee
wn:arrhenatherum elatius
wn:artemisia californica
wn:artemisia dracunculus
wn:artemisia gnaphalodes
wn:artemisia ludoviciana
wn:artemisia stelleriana
wn:artemision at ephesus
wn:arteria intercostalis
wn:arterial blood vessel
wn:arthur edwin kennelly
wn:articles of agreement
wn:as luck would have it
wn:asarum shuttleworthii
wn:ascension of the lord
wn:asclepias curassavica
wn:asparagus officinales
wn:aspergillus fumigatus
wn:asplenium platyneuron
wn:asplenium trichomanes
wn:astreus hygrometricus
wn:astrophyton muricatum
wn:athyrium filix-femina
wn:atmospheric condition
wn:atrioventricular node
wn:august von wassermann
wn:augustin jean fresnel
wn:australian blacksnake
wn:australian bonytongue
wn:australian grass tree
wn:australian reed grass
wn:australian sword lily
wn:australian turtledove
wn:austronesian language
wn:automotive technology
wn:aversive conditioning
wn:avicennia officinalis
wn:avogadro's hypothesis
wn:azerbajdzhan republic
==== *-lev-know ====
easton:Knop
easton:Snow
gaz2k-counties:Knox
gaz2k-places:Knox
gcide:Aknow
gcide:Enow
gcide:Gnow
gcide:Knaw
gcide:Knew
gcide:Knob
gcide:Knop
gcide:Knor
gcide:knot
gcide:Known
gcide:Now
gcide:Snow
gcide:Ynow
moby-thesaurus:knob
moby-thesaurus:knot
moby-thesaurus:now
moby-thesaurus:snow
vera:now
wn:knob
wn:knot
wn:known
wn:knox
wn:now
wn:snow
==== END ====
