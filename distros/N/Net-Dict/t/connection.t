#!./perl
#
#

use Net::Dict;
use strict;
$^W = 1;

use Test::More 0.88;
use Test::RequiresInternet 0.05 ('dict.org' => 2628);
use Test::Differences qw/ eq_or_diff /;

use lib 't/lib';
use Net::Dict::TestConfig qw/ $TEST_HOST $TEST_PORT /;

my $WARNING;
my %TESTDATA;
my $section;
my @caps;
my $description;
my $dict;
my $string;

plan tests => 17;

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
ok(defined($TEST_HOST) && defined($TEST_PORT), "have a HOST and PORT defined");

#-----------------------------------------------------------------------
# constructor with no arguments - should result in a die()
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(); };
ok((not defined $dict) && $@ =~ /takes at least a HOST/,
   "Not passing a DICT server name should croak");

#-----------------------------------------------------------------------
# pass a hostname of 'undef' we should get undef back
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(undef); };
ok((not defined($dict)),
   "passing undef for hostname should fail");

#-----------------------------------------------------------------------
# pass a hostname of empty string, should get undef back
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new(''); };
ok(!$@ && !defined($dict),
   "Passing an empty hostname should result in undef");

#-----------------------------------------------------------------------
# Ok hostname given, but unknown argument passed.
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($TEST_HOST, Foo => 'Bar'); };
ok($@ && !defined($dict) && $@ =~ /unknown argument/,
   "passing an unknown argument to constructor should croak");

#-----------------------------------------------------------------------
# Ok hostname given, odd number of following arguments passed
#	=> return undef
#	=> doesn't die
#-----------------------------------------------------------------------
eval { $dict = Net::Dict->new($TEST_HOST, 'Foo'); };
ok($@ =~ /odd number of arguments/,
   "Odd number of arguments after hostname should croak");

#-----------------------------------------------------------------------
# Valid hostname and port - should succeed
#-----------------------------------------------------------------------
$WARNING = undef;
eval { $dict = Net::Dict->new($TEST_HOST, Port => $TEST_PORT); };
ok(!$@ && defined $dict && !defined $WARNING,
   "valid hostname and port to constructor should return object");

#-----------------------------------------------------------------------
# Check the serverinfo string.
# We compare this with what we expect to get from dict.org
# We strip off the first two lines, because they have time-varying
# information; but we make sure they're the lines we think they are.
#-----------------------------------------------------------------------
$description = "check serverinfo string";
my $serverinfo = $dict->serverInfo();
if (exists $TESTDATA{serverinfo}
    && defined($serverinfo)
    && do { $serverinfo =~ s/^dictd.*?\n//s}
    && do { $serverinfo =~ s/^On dict\.dict\.org.*?\)// }
   )
{
    eq_or_diff($serverinfo, $TESTDATA{serverinfo}, $description);
}
else {
    fail($description);
}

#-----------------------------------------------------------------------
# METHOD: status
# call with an argument - should die since it takes no args.
#-----------------------------------------------------------------------
eval { $string = $dict->status('foo'); };
ok ($@ && $@ =~ /takes no arguments/,
    "status() with an argument should croak");

#-----------------------------------------------------------------------
# METHOD: status
# call with no args, and check that the general format of the string
# is what we expect
#-----------------------------------------------------------------------
eval { $string = $dict->status(); };
ok(!$@ && defined $string && $string =~ m!^status \[d/m/c.*\]$!,
   "status() with no args should result in a particular format string");

#-----------------------------------------------------------------------
# METHOD: capabilities
# call with an arg - doesn't take any, and should die
#-----------------------------------------------------------------------
eval { @caps = $dict->capabilities('foo'); };
ok($@ && $@ =~ /takes no arguments/,
   "passing an argument when getting capabilities should croak");

#-----------------------------------------------------------------------
# METHOD: capabilities
#-----------------------------------------------------------------------
$description = "capabilities() should return a lit of them";
if ($dict->can('capabilities')
    && eval { @caps = $dict->capabilities(); }
    && !$@
    && @caps > 0
    && do { $string = join(':', sort(@caps)); 1;}
   )
{
    eq_or_diff($string."\n", $TESTDATA{'capabilities'}, $description);
}
else {
    fail($description);
}

#-----------------------------------------------------------------------
# METHOD: has_capability
# no argument passed
#-----------------------------------------------------------------------
ok($dict->can('has_capability')
        && do { eval { $dict->has_capability(); }; 1;}
        && $@
        && $@ =~ /takes one argument/,
   "no argument passed to has_capability() should croak");

#-----------------------------------------------------------------------
# METHOD: has_capability
# pass two capability names - should also die()
#-----------------------------------------------------------------------
ok($dict->can('has_capability')
        && do { eval { $dict->has_capability('mime', 'auth'); }; 1; }
        && $@
        && $@ =~ /takes one argument/,
   "passing to arguments to has_capability() should croak");

#-----------------------------------------------------------------------
# METHOD: has_capability
#-----------------------------------------------------------------------
ok($dict->can('has_capability')
        && $dict->has_capability('mime')
        && $dict->has_capability('auth')
        && !$dict->has_capability('foobar'),
    "check valid use of has_capability()");

#-----------------------------------------------------------------------
# METHOD: msg_id
# with an argument - should cause it to die()
#-----------------------------------------------------------------------
ok($dict->can('msg_id')
        && do { eval { $string = $dict->msg_id('dict.org'); }; 1;}
        && $@
        && $@ =~ /takes no arguments/,
    "Passing an argument to msg_id() should croak");

#-----------------------------------------------------------------------
# METHOD: msg_id
# with no arguments, should get valid id back, of the form <...>
#-----------------------------------------------------------------------
ok($dict->can('msg_id')
    && do { eval { $string = $dict->msg_id(); }; 1;}
    && !$@
    && defined($string)
    && $string =~ /^<[^<>]+>$/,
   "calling msg_id() with no arguments should return id of form <...>");


exit 0;

__DATA__
==== serverinfo ====


Database      Headwords         Index          Data  Uncompressed
gcide              203645       3859 kB         12 MB         38 MB
wn                 147311       3002 kB       9247 kB         29 MB
moby-thesaurus      30263        528 kB         10 MB         28 MB
elements              142          2 kB         17 kB         53 kB
vera                12016        136 kB        213 kB        709 kB
jargon               2314         40 kB        565 kB       1346 kB
foldoc              15170        301 kB       2215 kB       5423 kB
easton               3968         64 kB       1077 kB       2648 kB
hitchcock            2619         34 kB         33 kB         85 kB
bouvier              6797        128 kB       2338 kB       6185 kB
devil                1008         15 kB        161 kB        374 kB
world02               280          5 kB       1543 kB       7172 kB
gaz2k-counties      12875        269 kB        280 kB       1502 kB
gaz2k-places        51361       1006 kB       1711 kB         13 MB
gaz2k-zips          33249        454 kB       2123 kB         15 MB
--exit--                0          0 kB          0 kB          0 kB
fd-hrv-eng          79814       1816 kB       1633 kB       4819 kB
fd-fin-por          10755        190 kB        512 kB       1306 kB
fd-fin-bul          10789        185 kB        525 kB       1348 kB
fd-fra-bul          11009        182 kB        290 kB        793 kB
fd-deu-swe          38957        730 kB       2348 kB       6102 kB
fd-fin-swe          12309        221 kB        599 kB       1525 kB
fd-jpn-rus          15500        289 kB        304 kB       1439 kB
fd-wol-fra            602          6 kB          6 kB         13 kB
fd-fra-pol          13698        243 kB        318 kB        834 kB
fd-eng-deu          93283       1707 kB       1403 kB       4123 kB
fd-deu-nld          12818        204 kB        267 kB        709 kB
fd-por-eng          10667        169 kB        186 kB        487 kB
fd-spa-deu          22974        370 kB        325 kB       1125 kB
fd-ces-eng            494          6 kB          8 kB         16 kB
fd-swe-fin          10531        170 kB        284 kB        726 kB
fd-eng-pol          16382        249 kB        473 kB       1272 kB
fd-pol-nor          12268        208 kB        631 kB       1654 kB
fd-eng-rom            996         14 kB         18 kB         46 kB
fd-eng-fra           8805        128 kB        134 kB        339 kB
fd-fin-ell          13252        232 kB        650 kB       1677 kB
fd-eng-lit           6260         94 kB        206 kB        516 kB
fd-ckb-kmr           7851        114 kB        145 kB        370 kB
fd-ita-eng           3435         48 kB         52 kB        128 kB
fd-pol-eng          28609        517 kB       1611 kB       4288 kB
fd-gle-eng           1191         16 kB         18 kB         43 kB
fd-eng-tur          36595        585 kB       1891 kB       4713 kB
fd-gle-pol            286          4 kB          5 kB         11 kB
fd-pol-deu          18379        333 kB       1005 kB       2710 kB
fd-fra-spa          35936        671 kB        751 kB       2169 kB
fd-lit-eng           7037        117 kB        179 kB        497 kB
fd-eng-jpn          28680        496 kB       1200 kB       2850 kB
fd-ara-eng          53002       1285 kB       1051 kB       2967 kB
fd-nld-ita          10601        174 kB        362 kB        935 kB
fd-eng-lat           3032         40 kB         39 kB         96 kB
fd-eng-hun          89685       1933 kB       2822 kB       7827 kB
fd-ita-jpn          11056        180 kB        252 kB        628 kB
fd-dan-eng           4003         55 kB         63 kB        155 kB
fd-hun-eng         139941       3395 kB       3355 kB       9744 kB
fd-pol-gle            278          3 kB          5 kB         10 kB
fd-fra-fin          12296        217 kB        292 kB        765 kB
fd-nld-swe          10041        164 kB        344 kB        881 kB
fd-nld-eng          22753        377 kB        371 kB        956 kB
fd-deu-kur          22573        376 kB        237 kB        844 kB
fd-deu-spa          27558        501 kB       1620 kB       4096 kB
fd-eng-afr           6403         85 kB         86 kB        231 kB
fd-eng-swe           5485         71 kB         74 kB        181 kB
fd-jpn-deu         242817       5280 kB       6264 kB         24 MB
fd-epo-eng         190437       3296 kB       2793 kB       8143 kB
fd-pol-nld          10511        180 kB        567 kB       1495 kB
fd-lat-deu          12279        190 kB        161 kB        519 kB
fd-eng-cym          12636        203 kB        187 kB        596 kB
fd-por-spa          10587        165 kB        178 kB        532 kB
fd-eng-spa           5913         76 kB         78 kB        197 kB
fd-swe-tur          11801        183 kB        308 kB        779 kB
fd-tur-eng           1032         14 kB         16 kB         36 kB
fd-tur-deu            947         13 kB         16 kB         36 kB
fd-pol-fra          16347        294 kB        864 kB       2330 kB
fd-eng-por          15865        250 kB        280 kB        741 kB
fd-ita-pol          11135        180 kB        229 kB        611 kB
fd-eng-ces         150010       2454 kB       1772 kB       6362 kB
fd-deu-tur          36225        585 kB        356 kB       1394 kB
fd-fra-jpn          13063        242 kB        330 kB        845 kB
fd-cym-eng          12636        195 kB        182 kB        535 kB
fd-bre-fra          38278        632 kB        516 kB       1450 kB
fd-jpn-fra          36442        654 kB        693 kB       3431 kB
fd-nld-deu          17230        278 kB        314 kB        817 kB
fd-eng-nld           7720        119 kB        165 kB        415 kB
fd-deu-por           8748        133 kB        155 kB        403 kB
fd-eng-hrv          59200       1239 kB       1400 kB       3983 kB
fd-mkd-bul           4552         99 kB         63 kB        229 kB
fd-swe-eng           5226         71 kB         77 kB        193 kB
fd-pol-spa          17143        310 kB        971 kB       2573 kB
fd-jpn-eng         375820       8781 kB       8695 kB         36 MB
fd-eng-ell          20990        357 kB        415 kB       1205 kB
fd-ita-por          11612        189 kB        225 kB        629 kB
fd-pol-swe          10401        183 kB        551 kB       1472 kB
fd-pol-fin          11650        202 kB        628 kB       1660 kB
fd-kur-tur          24383        359 kB        256 kB        804 kB
fd-ita-swe          11682        190 kB        234 kB        630 kB
fd-eng-swh           1456         18 kB         17 kB         48 kB
fd-kha-eng           2294         32 kB         38 kB         97 kB
fd-fin-eng          32379        657 kB       1367 kB       3861 kB
fd-eng-hin          25648        420 kB       1198 kB       3616 kB
fd-spa-eng           4508         67 kB         77 kB        189 kB
fd-afr-eng           5135         72 kB         82 kB        213 kB
fd-ita-fin          13313        221 kB        277 kB        750 kB
fd-eng-fin          55739       1001 kB       2406 kB       6251 kB
fd-fra-ita          38384        722 kB        776 kB       2323 kB
fd-deu-rus          17748        321 kB       1122 kB       2870 kB
fd-deu-bul           8860        149 kB        535 kB       1338 kB
fd-deu-pol          16263        289 kB        988 kB       2463 kB
fd-srp-eng            401          6 kB          7 kB         16 kB
fd-kur-deu          22041        331 kB        214 kB        749 kB
fd-spa-por            376          4 kB          6 kB         12 kB
fd-swe-pol          10805        170 kB        336 kB        837 kB
fd-swe-rus          13608        220 kB        414 kB       1100 kB
fd-nld-spa          24989        433 kB        766 kB       2010 kB
fd-swh-pol           1325         16 kB         16 kB         42 kB
fd-oci-cat          16685        256 kB         85 kB        401 kB
fd-ita-rus          12041        201 kB        285 kB        813 kB
fd-fra-ell          11139        187 kB        278 kB        759 kB
fd-eng-srp            596          7 kB          8 kB         20 kB
fd-fra-tur           7726        128 kB        186 kB        471 kB
fd-fra-eng           8511        131 kB        142 kB        385 kB
fd-ita-ell          10523        171 kB        243 kB        678 kB
fd-kur-eng           5214         68 kB         47 kB        144 kB
fd-swe-deu          26584        452 kB        850 kB       2220 kB
fd-swe-fra          13446        217 kB        371 kB        960 kB
fd-swe-lat           8118        120 kB        201 kB        511 kB
fd-swe-ell          14195        225 kB        412 kB       1089 kB
fd-eng-rus           1699         23 kB         25 kB         66 kB
fd-pol-por          12285        213 kB        658 kB       1746 kB
fd-gla-deu            263          3 kB          5 kB         10 kB
fd-eng-ita           4525         59 kB         59 kB        157 kB
fd-pol-ita          14986        271 kB        764 kB       2103 kB
fd-fra-swe          14953        268 kB        367 kB        972 kB
fd-isl-eng          11225        165 kB        146 kB        410 kB
fd-swe-spa          14691        236 kB        404 kB       1041 kB
fd-nno-nob          67993       1075 kB        280 kB       1252 kB
fd-swe-ita          13508        217 kB        364 kB        950 kB
fd-fra-deu          31223        580 kB        820 kB       2169 kB
fd-fin-ita          10326        183 kB        491 kB       1261 kB
fd-nld-fra          16776        269 kB        256 kB        666 kB
fd-eng-ara          87430       1413 kB       1095 kB       3873 kB
fd-slk-eng            833         11 kB         13 kB         28 kB
fd-fra-por          16540        291 kB        389 kB       1038 kB
fd-spa-ast          49258        791 kB        557 kB       1836 kB
fd-fin-jpn          14970        266 kB        736 kB       1811 kB
fd-deu-ita           4460         64 kB         62 kB        162 kB
fd-swh-eng           2681         33 kB         36 kB        107 kB
fd-fin-nor          10140        176 kB        455 kB       1171 kB
fd-fra-nld           9610        151 kB        193 kB        477 kB
fd-lat-eng           2311         31 kB         35 kB         89 kB
fd-eng-bul          16767        270 kB        738 kB       1964 kB
fd-deu-fra          34513        635 kB       2047 kB       5196 kB
fd-swe-bul          12534        194 kB        345 kB        916 kB
fd-deu-eng          81627       1612 kB       1343 kB       4099 kB
fd-pol-rus          21404        390 kB       1150 kB       3295 kB
fd-ita-deu           2929         40 kB         50 kB        119 kB
fd-eng-gle           1365         17 kB         18 kB         41 kB
fd-swe-por          11892        187 kB        320 kB        816 kB
fd-afr-deu           3806         52 kB         69 kB        179 kB
fd-por-deu           8300        127 kB        159 kB        409 kB
fd-fra-bre          36026        624 kB        776 kB       2249 kB
fd-san-deu            112          2 kB          2 kB          5 kB
fd-kha-deu           1013         13 kB         12 kB         32 kB
fd-fra-rus          12604        214 kB        252 kB        706 kB
fd-pol-ell          10793        191 kB        658 kB       1743 kB
english                 0          0 kB          0 kB          0 kB
trans                   0          0 kB          0 kB          0 kB
all                     0          0 kB          0 kB          0 kB

==== capabilities ====
auth:mime
==== END ====
