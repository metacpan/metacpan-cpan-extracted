# User-supplied test cases.
# (These *were* bugs :-)

use String::Approx qw(amatch aindex adist);
use Test::More tests => 42;

chdir('t') or die "could not chdir to 't'";

require './util';

local $^W = 1;

# test long pattern both matching and not matching
# Thanks to Alberto Fontaneda <alberfon@ctv.es>
# for this test case and also thanks to Dmitrij Frishman
# <frishman@mips.biochem.mpg.de> for testing this test.
{
my @l = ('perl warks fiine','parl works fine', 'perl worrs', 'perl warkss');
my @m = amatch('perl works fin', [2] , @l);
ok($m[0] eq 'perl warks fiine' &&
   $m[1] eq 'parl works fine');
#print "m = (@{[join(':',@m)]})\n";
}

# Slaven Rezic <eserte@cs.tu-berlin.de>

{
my @w=('one hundred','two hundred','three hundred','bahnhofstr. (koepenick)');
my @m=amatch('bahnhofstr. ', ['i',3], @w);
ok(t(['bahnhofstr. (koepenick)'],[@m]));
}

# Greg Ward <greg@bic.mni.mcgill.ca>

ok(amatch('mcdonald', 'macdonald'));
ok(amatch('macdonald', 'mcdonald'));

ok(amatch('mcdonald', ['I0'], 'macdonald'));

ok(amatch('mcdonald', ['I1'], 'mcdonaald'));
ok(!amatch('mcdonald', ['I1'], 'mcdonaaald'));

ok(amatch('mcdonald', ['1I1'], 'mcdonaald'));
ok(amatch('mcdonald', ['2I2'], 'mcdonaaald'));

# Kevin Greiner <kgreiner@geosys.com>

@IN = ("AK_ANCHORAGE A-7 NW","AK A ANCHORAGE B-8 NE");
$Title = "AK_ANCHORAGE A-7 NE";
ok(amatch($Title, @IN));

# Ricky Houghton <ricky.houghton@cs.cmu.edu>

@names = ("madeleine albright","william clinton");
@matches = amatch("madeleine albriqhl",@names);
ok($matches[0] eq "madeleine albright");

# test 9: Jared August <rudeop@skapunx.net>

ok(amatch("Dopeman (Remix)",["i","50%"],"Dopeman (Remix)"));

# Steve A. Chervitz <sac@genome.Stanford.edu>

# Short vs. Long behaved differently than Long vs. Short.

# s1 and s1_1 are identical except for an extra extension at end of s1.

$s1   = "MSRTGHGGLMPVNGLGFPPQNVARVVVWECLNEHSRWRPYTATVCHHIENVLKEDARGSVVLGQVDAQ".
    "LVPYIIDLQSMHQFRQDTGTMRPVRRNFYDPSSAPGKGIVWEWENDGGAWTAYDMDICITIQNAYEKQHPWLW_GBH";

$s1_1 = "MSRPGHGGLMPVNGLGFPPQNVARVVVWECLNEHSRWRPYTATVCHHIENVLKEDARGSVVLGQVDAQ".
    "LVPYIIDLQSMHQFRQDTGTMRPVRRNFYDPSSAPGKGIVWEWENDGGAWTAYDMDICITIQNAYEKQHPWLW";

ok(amatch($s1, ['5%'], $s1_1));  # this failed to match

ok(amatch($s1_1, ['5%'], $s1));

# s1_1 vs. s1: (attempting to disallow insertions).

ok(amatch($s1_1, ['5%','I0'], $s1));

#-----------------------------------------------------------------------
# Position dependency of approximate matching.

# There is a position dependency for matching. If two strings differ
# at two neighboring (or very close) positions, they will not match
# with approximation.  If the differences are well-separated, they
# will match with approximation.

$s2   = "DLSSLGFCYLIYFNSMSQMNRQTRRRRRLRRRLDLAYPLTVGSIPKSQSWPVGASSGQPCSCQQCLLVNSTRAVSN".
    "VILASQRRKVPPAPPLPPPPPPGGPPGALAVRPSATFTGAALWAAPAAGPAEPAPPPGAPPRSPGAPGGARTPGQNNLNR".
    "PGPQRTTSVSARASIPPGVPALPVKNLNGTGPVHPALAGMTGILLCAAGLPVCLTRAPKPILHPPPVSKSDVKPVPGVPG".
    "VCRKTKKKHLKKSKNPEDVVRRYMQKVKNPPDEDCTICMERLVTASGYEGVLRHKGVRPELVGRLGRCGHMYHLLCLVAMY".
    "SNGNKDGSLQCPTCKAIYGEKTGTQPPGKMEFHLIPHSLPGFPDTQTIRIVYDIPTGIQGPEHPNPGKKFTARGFPRHCYL".
    "PNNEKGRKVLRLLITAWERRLIFTIGTSNTTGESDTVVWNEIHHKTEFGSNLTGHGYPDASYLDNVLAELTAQGVSEAAGKA";

# s2_1 has two nearby substitutions relative to s2 indicated with '_'

$s2_1  = "DLSSLGFCYL_YFNSMSQMN_QTRRRRRLRRRLDLAYPLTVGSIPKSQSWPVGASSGQPCSCQQCLLVNSTRAVSN".
    "VILASQRRKVPPAPPLPPPPPPGGPPGALAVRPSATFTGAALWAAPAAGPAEPAPPPGAPPRSPGAPGGARTPGQNNLNR".
    "PGPQRTTSVSARASIPPGVPALPVKNLNGTGPVHPALAGMTGILLCAAGLPVCLTRAPKPILHPPPVSKSDVKPVPGVPG".
    "VCRKTKKKHLKKSKNPEDVVRRYMQKVKNPPDEDCTICMERLVTASGYEGVLRHKGVRPELVGRLGRCGHMYHLLCLVAMY".
    "SNGNKDGSLQCPTCKAIYGEKTGTQPPGKMEFHLIPHSLPGFPDTQTIRIVYDIPTGIQGPEHPNPGKKFTARGFPRHCYL".
    "PNNEKGRKVLRLLITAWERRLIFTIGTSNTTGESDTVVWNEIHHKTEFGSNLTGHGYPDASYLDNVLAELTAQGVSEAAGKA";


# s2_2 has two far apart substitutions relative to s2 indicated with '_'

$s2_2  = "DLSSLGFC_LIYFNSMSQMNRQTRRRRRLRRRLDLAYPLTVGSIPKSQSWPVGASSGQPCSCQQCLLVNSTRAVSN".
    "VILASQRRKVPPAPPLPPPPPPGGPPGALAVRPSATFTGAALWAAPAAGPAEPAPPPGAPPRSPGAPGGARTPGQNNLNR".
    "PGPQRTTSVSARASIPPGVPALPVKNLNGTGPVHPALAGMTGILLCAAGLPVCLTRAPKPILHPPPVSKSDVKPVPGVPG".
    "VCRKTKKKHLKKSKNPEDVVRRYMQKVKNPPDEDCTICMERLVTASGYEGVLRHKGVRPELVGRLGRCGHMYHLLCLVAMY".
    "SNGNKDGSLQCPTCKAIYGEKTGTQPPGKMEFHLIPHSLPGFPDTQTIRIVYDIPTGIQGPEHPNPGKKFTARGFPRHCYL".
    "PNNEKGRKVLRLLITAWERRLIFTIGTSNTTGESDTVVWNEIHHKTEFGSNLTG_GYPDASYLDNVLAELTAQGVSEAAGKA";


# s2 vs s2_1: (substitutions close together)

ok(amatch($s2, [10], $s2_1));

# s2 vs s2_2: (substitutions far apart)

ok(amatch($s2, [10], $s2_2));

#-----------------------------------------------------------------------
# Difference in behavior of % differences versus absolute number of
# differences.

$s3 =  "MNIFEMLRIDEGLRLKIYKDTEGYYTIGIGHLLTKSPSLNAAKSELDKAIGRNCNGVITKDEAEKLFNQDVDAAVRG".
    "ILRNAKLKPVYDSLDAVRRCALINMVFGMGETGVAGFTNSLRMLQQKRWDEAAVNLAKSRWYNQTPNRAKRVITTFRTGT".
    "WDAYKNL";

# s3_1 contains two substitutions '_' and one deletion relative to s3.
$s3_1 = "MNIFEMLRIDEGLRLKIYKDTEGYYTIGIGHLLTKSPSLNAAKSELDKAIGRN_NGVITKDEAEKLFNQDVDAVRG".
    "ILRNAKLKPVYDSLDAVRRCALINMVF_MGETGVAGFTNSLRMLQQKRWDEAAVNLAKSRWYNQTPNRAKRVITTFRTGT".
    "WDAYKNL";

# s3 vs s3_1: (matching with 10% differences)

ok(amatch($s3, ['10%'], $s3_1));

# s3 vs s3_1: (matching with 10 differences)

ok(amatch($s3, ['10'], $s3_1));

# Bob J.A. Schijvenaars <schijvenaars@mi.fgg.eur.nl>

@gloslist = ('computer', 'computermonitorsalesman');
@matches = amatch('computers', [1,'g'], @gloslist);
$a = '';
for (@matches) {
   $a .= "|$_|";
}
@matches = amatch('computers', [2,'g'], @gloslist);
$b = '';
for (@matches) {
   $b .= "|$_|";
}

ok($a eq $b and $a eq "|computer||computermonitorsalesman|");

# Rick Wise <rwise@lcc.com>

ok(amatch('abc', [10], 'abd'));

# Ilya Sandler <sandler@etak.com>

$_="ABCDEF";
ok(!amatch("ABCDEF","VWXYZ"));

ok(amatch("BURTONUPONTRENT",['5'], "BURTONONTRENT"));

ok(amatch("BURTONONTRENT",['5'], "BURTONUPONTRENT"));

# Chris Rosin <crosin@cparity.com> and
# Mark Land <mark@cparity.com>.

ok(!amatch("Karivaratharajan", "Rajan"));

ok(amatch("Rajan", "Karivaratharajan"));

ok(amatch("Ferna", "Fernandez"));

ok(!amatch("Fernandez", "Ferna"));

# Mitch Helle <MHelle@linguistech.com>

ok(!amatch('ffffff', 'a'));

ok(!amatch('fffffffffff', 'a'));

ok(!amatch('fffffffffffffffffffff', 'ab'));

# Anirvan Chatterjee <anirvan@chatterjee.net>

ok(amatch("", "foo"));

# Rob Fugina

open(MAKEFILEPL, "../Makefile.PL") or die "$0: failed to open Makefile.PL: $!";
# Don't let a debugging version escape the laboratory.
my $debugging = grep {/^[^#]*-DAPSE_DEBUGGING/} <MAKEFILEPL>;
ok(!$debugging);
close(MAKEFILEPL);
warn "(You have -DAPSE_DEBUGGING turned on!)\n" if $debugging;

# David Curiel
is(aindex("xyz", "abxefxyz"), 5);

# Stefan Ram <ram@cis.fu-berlin.de>

is(aindex( "knral", "nisinobikttatnbankfirknalt" ), 21);

is(aindex( "knral", "nbankfirknalt"), 8);

is(aindex( "knral", "nkfirknalt"), 5);

# Chris Rosin <crosin@cparity.com>

is(adist('MOM','XXMOXXMOXX'), 1);

# Frank Tobin <ftobin@uiuc.edu>

is(aindex('----foobar----',[1],'----aoobar----'), 0);

# Damian Keefe <damian.keefe@incyte.com>

is(aindex('tccaacttctctgtgactgaccaaagaa','tctttgcatccaatactccaacttctctgtggctgaccaaagaattggcacctatcttgccagtcaggtagttctgatgggtccagcacagactggctgcctgggggagaaagacagcattgatttgaagtggtgaacactataactcccctagctcatcacaaaacaagcagacaagaaccacagcttc'), 16);

# Juha Muilu <muilu@ebi.ac.uk>

is(aindex("pattern", "aaaaaaaaapattern"), 9);

# Ji Y Park <jypark@Stanford.EDU>
# 0% must mean 0.

$_="TTES";
ok(!amatch("test", ["i I0% S0% D0%"]));

# eof

