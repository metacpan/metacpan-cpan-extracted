#!./perl
#
# define.t - Net::Dict testsuite for define() method
#

use Test::More 0.88;
use Test::RequiresInternet 0.05 ('dict.org' => 2628);
use Net::Dict;
use lib 't/lib';
use Net::Dict::TestConfig qw/ $TEST_HOST $TEST_PORT /;

$^W = 1;

my $WARNING;
my %TESTDATA;
my $defref;
my $section;
my $string;
my $dbinfo;
my $title;

plan tests => 16;

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
   "do we have test host and port");

#-----------------------------------------------------------------------
# connect to server
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($TEST_HOST, Port => $TEST_PORT); };
ok(!$@ && defined $dict, "connect to DICT server");

#-----------------------------------------------------------------------
# call define() with no arguments - should die
#-----------------------------------------------------------------------
eval { $defref = $dict->define(); };
ok($@ && $@ =~ /takes at least one argument/,
   "define() with no arguments should croak");

#-----------------------------------------------------------------------
# try and get a definition of something which won't have a definition
# note: at this point we're using the default of '*' for dicts - ie all
#-----------------------------------------------------------------------
eval { $defref = $dict->define('asdfghijkl'); };
ok(!$@ && defined $defref && int(@{$defref}) == 0,
   "requesting a definition for a non-existent word should return no entries");

#-----------------------------------------------------------------------
# METHOD: define
# get definitions for biscuit, using the default of '*' for DBs
#-----------------------------------------------------------------------
$string = '';
$title  = "do we get expected definitions for 'biscuit'";
eval { $defref = $dict->define('biscuit'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $entry->[1] =~ s/\r//sg;
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    })
{
    is($string, $TESTDATA{'*-biscuit'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: define
# get definitions for biscuit, having set user dbs to (), and not
# giving any as args - should croak
#-----------------------------------------------------------------------
$dict->setDicts();
eval { $defref = $dict->define('biscuit'); };
ok($@ && $@ =~ /select some dictionaries/,
   "calling define() after selecting empty DB list should croak");

#-----------------------------------------------------------------------
# METHOD: define
# get definitions for biscuit, specifying '*' explicitly for dicts
#-----------------------------------------------------------------------
$string = '';
$title  = "check definitions for 'biscuit', setting '*' for DBs";
eval { $defref = $dict->define('biscuit', '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $entry->[1] =~ s/\r//sg;
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    })
{
    is($string, $TESTDATA{'*-biscuit'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: define
# get definitions for biscuit, specifying '!' explicitly for dicts
#-----------------------------------------------------------------------
$string = '';
$title  = "check result for 'biscuit' with DB set to '!'";
eval { $defref = $dict->define('biscuit', '!'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    })
{
    is($string, $TESTDATA{'!-biscuit'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: define
# get definition for noun phrase (more than one word, separated
# by spaces), specifying all dicts ('*')
#-----------------------------------------------------------------------
$string = '';
$title  = "Test results for noun phrase, with dicts set to '*'";
eval { $defref = $dict->define('antispasmodic agent', '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    })
{
    is($string, $TESTDATA{'*-antispasmodic_agent'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: define
# get definition a something containing an apostrophe ("ko'd")
# specifying all dicts ('*')
#-----------------------------------------------------------------------
$string = '';
$title  = "get definition for a word containing an apostrophe";
eval { $defref = $dict->define("ko'd", '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    })
{
    is($string, $TESTDATA{'*-kod'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: define
# get definition of something with apostrophe and a space.
# specifying all dicts ('*')
#-----------------------------------------------------------------------
$string = '';
$title  = "get definition of a noun phrase containing an apostrophe";
eval { $defref = $dict->define("oboe d'amore", '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    })
{
    is($string, $TESTDATA{'*-oboe_damore'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: define
# Very long entry, which also happens to have multiple spaces
#-----------------------------------------------------------------------
$string = '';
$title  = "test getting definition for very long entry, with spaces";
eval { $defref = $dict->define("Pityrogramma calomelanos aureoflava", '*'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    })
{
    is($string, $TESTDATA{'*-pityrogramma_calomelanos_aureoflava'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: define
# Valid word, invalid dbname - should return no entries
#-----------------------------------------------------------------------
eval { $defref = $dict->define('banana', 'web1651'); };
ok(!$@ && defined($defref) && int(@{$defref}) == 0,
   "valid word, invalid db name, should return 0 entries");

#-----------------------------------------------------------------------
# METHOD: define
# Call setDicts to select web1913, but then explicitly specify
# "wn" as the dictionary to search when calling define.
# the word ("banana") is in both dictionaries, but we should only
# get the definition for wn
#-----------------------------------------------------------------------
$string = '';
$title  = "search for a word, with DB passed to define()";
$dict->setDicts('web1913');
eval { $defref = $dict->define('banana', 'wn'); };
if (!$@
    && defined($defref)
    && do {
        foreach my $entry (sort {$a->[0] cmp $b->[0]} @{ $defref })
        {
            $string .= $entry->[0]."\n";
            $string .= $entry->[1];
        }
        1;
    })
{
    is($string, $TESTDATA{'wn-banana'}, $title);
}
else {
    fail($title);
}

#-----------------------------------------------------------------------
# METHOD: define
# Call define, passing undef for the word, and '*' for dicts
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->define(undef, '*'); };
ok(!$@ && !defined($defref)
    && $WARNING =~ /empty word passed to define/,
   "passing undef for the word should return undef");

#-----------------------------------------------------------------------
# METHOD: define
# Call define, passing empty string for the word, and '*' for dicts
#-----------------------------------------------------------------------
$WARNING = '';
eval { $defref = $dict->define('', '*'); };
ok(!$@
    && !defined($defref)
    && $WARNING =~ /empty word passed to define/,
   "passing an empty string returns undef");


exit 0;

__DATA__
==== *-biscuit ====
gcide
Biscuit \Bis"cuit\, n. [F. biscuit (cf. It. biscotto, Sp.
   bizcocho, Pg. biscouto), fr. L. bis twice + coctus, p. p. of
   coquere to cook, bake. See {Cook}, and cf. {Bisque} a kind of
   porcelain.]
   1. A kind of unraised bread, of many varieties, plain, sweet,
      or fancy, formed into flat cakes, and bakes hard; as, ship
      biscuit.
      [1913 Webster]

            According to military practice, the bread or biscuit
            of the Romans was twice prepared in the oven.
                                                  --Gibbon.
      [1913 Webster]

   2. A small loaf or cake of bread, raised and shortened, or
      made light with soda or baking powder. Usually a number
      are baked in the same pan, forming a sheet or card.
      [1913 Webster]

   3. Earthen ware or porcelain which has undergone the first
      baking, before it is subjected to the glazing.
      [1913 Webster]

   4. (Sculp.) A species of white, unglazed porcelain, in which
      vases, figures, and groups are formed in miniature.
      [1913 Webster]

   {Meat biscuit}, an alimentary preparation consisting of
      matters extracted from meat by boiling, or of meat ground
      fine and combined with flour, so as to form biscuits.
      [1913 Webster]
moby-thesaurus
52 Moby Thesaurus words for "biscuit":
   Brussels biscuit, Melba toast, adobe, bisque, bone, bowl, brick,
   brownie, cement, ceramic ware, ceramics, china, cookie, cracker,
   crock, crockery, date bar, dust, enamelware, firebrick, fruit bar,
   ginger snap, gingerbread man, glass, graham cracker, hardtack, jug,
   ladyfinger, macaroon, mummy, parchment, pilot biscuit, porcelain,
   pot, pottery, pretzel, refractory, rusk, saltine, sea biscuit,
   ship biscuit, shortbread, sinker, soda cracker, stick,
   sugar cookie, tile, tiling, urn, vase, wafer, zwieback


wn
biscuit
    n 1: small round bread leavened with baking-powder or soda
    2: any of various small flat sweet cakes (`biscuit' is the
       British term) [syn: {cookie}, {cooky}, {biscuit}]
==== !-biscuit ====
gcide
Biscuit \Bis"cuit\, n. [F. biscuit (cf. It. biscotto, Sp.
   bizcocho, Pg. biscouto), fr. L. bis twice + coctus, p. p. of
   coquere to cook, bake. See {Cook}, and cf. {Bisque} a kind of
   porcelain.]
   1. A kind of unraised bread, of many varieties, plain, sweet,
      or fancy, formed into flat cakes, and bakes hard; as, ship
      biscuit.
      [1913 Webster]

            According to military practice, the bread or biscuit
            of the Romans was twice prepared in the oven.
                                                  --Gibbon.
      [1913 Webster]

   2. A small loaf or cake of bread, raised and shortened, or
      made light with soda or baking powder. Usually a number
      are baked in the same pan, forming a sheet or card.
      [1913 Webster]

   3. Earthen ware or porcelain which has undergone the first
      baking, before it is subjected to the glazing.
      [1913 Webster]

   4. (Sculp.) A species of white, unglazed porcelain, in which
      vases, figures, and groups are formed in miniature.
      [1913 Webster]

   {Meat biscuit}, an alimentary preparation consisting of
      matters extracted from meat by boiling, or of meat ground
      fine and combined with flour, so as to form biscuits.
      [1913 Webster]
==== *-antispasmodic_agent ====
wn
antispasmodic agent
    n 1: a drug used to relieve or prevent spasms (especially of the
         smooth muscles) [syn: {antispasmodic}, {spasmolytic},
         {antispasmodic agent}]
==== *-oboe_damore ====
gcide
Oboe \O"boe\, n. [It., fr. F. hautbois. See {Hautboy}.] (Mus.)
   One of the higher wind instruments in the modern orchestra,
   yet of great antiquity, having a penetrating pastoral quality
   of tone, somewhat like the clarinet in form, but more
   slender, and sounded by means of a double reed; a hautboy.
   [1913 Webster]

   {Oboe d'amore} [It., lit., oboe of love], and {Oboe di
   caccia} [It., lit., oboe of the chase], are names of obsolete
      modifications of the oboe, often found in the scores of
      Bach and Handel.
      [1913 Webster]
wn
oboe d'amore
    n 1: an oboe pitched a minor third lower than the ordinary oboe;
         used to perform baroque music
==== *-kod ====
gcide
KO \KO\ v. t. [imp. & p. p. {KO'd}; p. pr. & vb. n. {KO'ing}.]
   To knock out; to deliver a blow that renders (the opponent)
   unconscious; -- used especially in boxing. [acronym]

   Syn: knockout.
        [WordNet 1.5]
gcide
KO'd \KO'd\ adj. [from {KO}, v. t.]
   rendered unconscious, usually by a blow.

   Syn: knocked out(predicate), kayoed, out(predicate), stunned.
        [WordNet 1.5]
wn
KO'd
    adj 1: knocked unconscious by a heavy blow [syn: {knocked
           out(p)}, {kayoed}, {KO'd}, {out(p)}, {stunned}]
==== *-pityrogramma_calomelanos_aureoflava ====
wn
Pityrogramma calomelanos aureoflava
    n 1: tropical American fern having fronds with light golden
         undersides [syn: {golden fern}, {Pityrogramma calomelanos
         aureoflava}]
==== wn-banana ====
wn
banana
    n 1: any of several tropical and subtropical treelike herbs of
         the genus Musa having a terminal crown of large entire
         leaves and usually bearing hanging clusters of elongated
         fruits [syn: {banana}, {banana tree}]
    2: elongated crescent-shaped yellow fruit with soft sweet flesh
==== END ====
