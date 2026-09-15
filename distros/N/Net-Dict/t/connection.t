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
    && do { $serverinfo =~ s/\A.*^Database/Database/ms }
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
vera                12665        144 kB        225 kB        746 kB
jargon               2314         40 kB        573 kB       1385 kB
foldoc              15295        304 kB       2226 kB       5451 kB
easton               3968         64 kB       1077 kB       2648 kB
hitchcock            2619         34 kB         33 kB         85 kB
bouvier              6797        128 kB       2338 kB       6185 kB
devil                1008         15 kB        161 kB        374 kB
world02               280          5 kB       1543 kB       7172 kB
gaz2k-counties      12875        269 kB        280 kB       1502 kB
gaz2k-places        51361       1006 kB       1711 kB         13 MB
gaz2k-zips          33249        454 kB       2123 kB         15 MB
--exit--                0          0 kB          0 kB          0 kB
fd-dan-eng           5103         73 kB         86 kB        218 kB
fd-rus-pol          12540        316 kB        427 kB       1298 kB
fd-fra-ell          13618        235 kB        512 kB       1319 kB
fd-eng-fin          73561       1366 kB       5563 kB         13 MB
fd-pol-nor          17123        296 kB        885 kB       2305 kB
fd-spa-deu          22974        370 kB        324 kB       1116 kB
fd-jpn-eng         375820       8802 kB       8886 kB         42 MB
fd-hun-eng         139941       3395 kB       3354 kB       9744 kB
fd-swe-spa          14968        252 kB        660 kB       1648 kB
fd-por-eng          10667        169 kB        186 kB        487 kB
fd-por-spa          11090        175 kB        235 kB        657 kB
fd-swe-pol          12752        207 kB        601 kB       1464 kB
fd-eng-hun          89685       1933 kB       2821 kB       7829 kB
fd-tur-jpn          11665        188 kB        269 kB        638 kB
fd-zho-nor          97070       1525 kB       2877 kB       8921 kB
fd-ita-swe          17844        301 kB        753 kB       1965 kB
fd-pol-bul          13551        241 kB        711 kB       1994 kB
fd-deu-fin          11657        207 kB        727 kB       1786 kB
fd-por-deu           8300        127 kB        159 kB        409 kB
fd-pol-gle            278          3 kB          5 kB         10 kB
fd-tur-eng           1032         14 kB         16 kB         36 kB
fd-deu-ell          10086        174 kB        686 kB       1684 kB
fd-ita-jpn          19313        327 kB        890 kB       2213 kB
fd-tur-fin          14813        245 kB        310 kB        804 kB
fd-kur-tur          24383        359 kB        256 kB        804 kB
german-english     613958         14 MB       9440 kB         33 MB
fd-fin-nor          13979        246 kB        630 kB       1598 kB
fd-ell-nld          11522        284 kB        288 kB        787 kB
fd-pol-por          11771        206 kB        639 kB       1679 kB
fd-wol-fra            602          6 kB          6 kB         13 kB
fd-lat-eng           2311         31 kB         35 kB         89 kB
fd-eng-rom            996         14 kB         18 kB         46 kB
english-german     578893         13 MB       9388 kB         34 MB
fd-ita-pol          18030        306 kB        770 kB       2004 kB
fd-nld-ita          10601        174 kB        362 kB        935 kB
fd-nld-deu          17230        278 kB        314 kB        814 kB
fd-eng-rus          59439       1062 kB       4725 kB         12 MB
fd-eng-swh           1456         18 kB         17 kB         48 kB
fd-fin-lat          10450        179 kB        477 kB       1193 kB
fd-swe-rus          11375        187 kB        543 kB       1381 kB
fd-nld-bul          11790        195 kB        549 kB       1383 kB
fd-rus-por          10275        257 kB        393 kB       1176 kB
fd-pol-swe          12485        224 kB        688 kB       1789 kB
fd-jpn-rus          15500        289 kB        308 kB       1560 kB
fd-nld-swe          12595        212 kB        560 kB       1410 kB
fd-zho-ind          82910       1302 kB       2476 kB       7733 kB
fd-fin-lit          12176        212 kB        567 kB       1431 kB
fd-ell-eng          39037       1041 kB        957 kB       2740 kB
fd-pol-nld          16091        284 kB        874 kB       2290 kB
fd-eng-bul          34219        568 kB       2649 kB       6838 kB
fd-fra-spa          48689        922 kB       1440 kB       3906 kB
fd-fra-nld           9610        151 kB        193 kB        477 kB
fd-deu-por           8728        133 kB        155 kB        402 kB
fd-ell-ita          11324        278 kB        273 kB        757 kB
fd-pol-ell          13740        247 kB        841 kB       2195 kB
fd-eng-cym          12636        203 kB        187 kB        596 kB
fd-eng-srp            596          7 kB          8 kB         20 kB
fd-tur-deu            947         13 kB         16 kB         36 kB
fd-cat-ita          12529        206 kB        444 kB       1352 kB
fd-spa-eng           4508         67 kB         77 kB        188 kB
fd-ell-lit          13483        325 kB        321 kB        900 kB
fd-fin-bul          15092        265 kB        736 kB       1873 kB
fd-kha-eng           2294         32 kB         38 kB         98 kB
fd-rus-deu          22653        585 kB        875 kB       2607 kB
fd-nno-nob          67993       1075 kB        280 kB       1252 kB
fd-ell-swe          12232        302 kB        298 kB        821 kB
fd-pol-ita          21598        393 kB       1130 kB       3031 kB
fd-bre-fra          38278        632 kB        516 kB       1450 kB
fd-nld-ind          10795        179 kB        326 kB        821 kB
fd-ell-jpn          12071        295 kB        316 kB        842 kB
fd-ita-por          12393        208 kB        539 kB       1429 kB
fd-pol-fra          20853        378 kB       1113 kB       2956 kB
fd-deu-spa          33824        625 kB       2080 kB       5216 kB
fd-por-fra          10463        166 kB        234 kB        626 kB
fd-pol-eng          39007        717 kB       2218 kB       5853 kB
fd-ell-por          13122        326 kB        320 kB        885 kB
fd-fra-por          24326        444 kB        861 kB       2219 kB
fd-fra-pol          20663        375 kB        717 kB       1807 kB
fd-swe-por          11006        178 kB        481 kB       1195 kB
fd-mkd-bul           4552         99 kB         63 kB        229 kB
fd-rus-eng          40784       1060 kB       1518 kB       4689 kB
fd-ita-fin          20819        356 kB        886 kB       2310 kB
fd-ell-bul          12018        292 kB        313 kB        910 kB
fd-san-deu            112          2 kB          2 kB          5 kB
fd-gle-pol            286          4 kB          5 kB         11 kB
fd-deu-eng         519423         12 MB         15 MB         95 MB
fd-eng-ces         150010       2442 kB       1228 kB       3763 kB
fd-nld-pol          12207        205 kB        561 kB       1391 kB
fd-nld-rus          12403        208 kB        608 kB       1529 kB
fd-deu-nld          12790        203 kB        266 kB        707 kB
fd-ita-bul          19893        337 kB        928 kB       2453 kB
fd-eng-jpn          35897        637 kB       2720 kB       6411 kB
fd-swe-ita          12420        204 kB        539 kB       1356 kB
fd-swe-eng           5226         71 kB         77 kB        193 kB
fd-fra-zho          10053        180 kB        410 kB        941 kB
fd-pol-ind          15979        276 kB        848 kB       2214 kB
fd-ell-spa          10708        259 kB        210 kB        567 kB
fd-eng-gle           1365         17 kB         18 kB         42 kB
fd-jpn-fra          36442        654 kB        702 kB       3765 kB
fd-ell-fin          12713        319 kB        320 kB        881 kB
fd-pol-jpn          13432        234 kB        793 kB       1988 kB
fd-pol-rus          27894        509 kB       1500 kB       4207 kB
fd-nld-cat          11009        183 kB        487 kB       1222 kB
fd-fin-cat          20665        373 kB        934 kB       2381 kB
fd-eng-pol          16382        249 kB        463 kB       1249 kB
fd-swe-bul          15204        247 kB        679 kB       1719 kB
fd-ell-pol          12364        303 kB        244 kB        659 kB
fd-ita-tur          17938        302 kB        785 kB       2032 kB
fd-deu-swe          44706        844 kB       2739 kB       7051 kB
fd-swe-lat          14116        225 kB        570 kB       1427 kB
fd-spa-por            376          4 kB          6 kB         12 kB
fd-swe-ell          15338        253 kB        700 kB       1767 kB
fd-fra-bul          17906        306 kB        481 kB       1296 kB
fd-gla-deu            263          3 kB          5 kB         10 kB
fd-nld-lat          12467        204 kB        515 kB       1309 kB
fd-ita-nld          10753        181 kB        493 kB       1294 kB
fd-cym-eng          12636        195 kB        182 kB        535 kB
fd-ces-eng            494          6 kB          8 kB         16 kB
fd-ell-cat          23272        585 kB        524 kB       1511 kB
fd-swe-tur          13151        216 kB        583 kB       1434 kB
fd-eng-deu         464234         10 MB         14 MB         75 MB
fd-fin-swe          16776        306 kB        812 kB       2058 kB
fd-swe-nld          11840        197 kB        512 kB       1288 kB
fd-oci-cat          16685        256 kB         85 kB        401 kB
fd-fin-deu          11794        210 kB        604 kB       1487 kB
fd-rus-ita          15495        399 kB        582 kB       1774 kB
fd-swe-deu          42704        758 kB       1848 kB       4802 kB
fd-kur-deu          22041        331 kB        214 kB        749 kB
fd-eng-dan            417          5 kB          7 kB         16 kB
fd-nld-eng          22753        377 kB        371 kB        956 kB
fd-rus-fra          22857        583 kB        919 kB       2826 kB
fd-ita-lit          12041        198 kB        542 kB       1406 kB
fd-fra-lit          11591        204 kB        428 kB       1091 kB
fd-ita-eng           3435         48 kB         52 kB        128 kB
fd-cat-spa          26569        473 kB        907 kB       2843 kB
fd-fin-nld          13386        241 kB        636 kB       1612 kB
fd-deu-rus          24254        443 kB       1585 kB       4023 kB
fd-fra-swe          18902        348 kB        667 kB       1698 kB
fd-ell-gle          17896        444 kB        430 kB       1230 kB
fd-fra-jpn          15702        296 kB        587 kB       1438 kB
fd-nld-fra          16776        269 kB        256 kB        666 kB
fd-fra-cat          22253        400 kB        724 kB       1895 kB
fd-ell-ind          16492        405 kB        384 kB       1095 kB
fd-ell-lat          13066        308 kB        206 kB        595 kB
fd-nld-ell          11392        189 kB        538 kB       1354 kB
fd-pol-lit          10154        175 kB        539 kB       1451 kB
fd-ita-gle          16250        271 kB        716 kB       1861 kB
fd-fin-ell          18310        327 kB        901 kB       2293 kB
fd-ckb-kmr           7851        114 kB        145 kB        370 kB
fd-fin-fra          11572        204 kB        572 kB       1429 kB
fd-slv-eng           5561         79 kB        103 kB        305 kB
fd-spa-tur          10074        168 kB        504 kB       1231 kB
fd-deu-fra          53738       1020 kB       3256 kB       8351 kB
fd-isl-eng          11225        165 kB        146 kB        410 kB
fd-deu-pol          21586        389 kB       1360 kB       3364 kB
fd-swe-gle          16161        261 kB        675 kB       1679 kB
fd-fra-bre          36026        624 kB        774 kB       2245 kB
fd-nld-lit          10585        168 kB        332 kB        836 kB
fd-deu-gle          16825        293 kB        967 kB       2398 kB
fd-fra-eng           8511        131 kB        142 kB        385 kB
fd-pol-spa          22690        415 kB       1283 kB       3371 kB
fd-fra-lat          12069        196 kB        272 kB        704 kB
fd-zho-lat         100911       1580 kB       2941 kB       9211 kB
fd-ita-ind          13353        222 kB        593 kB       1548 kB
fd-swe-zho          11083        176 kB        488 kB       1133 kB
fd-spa-fra          12145        208 kB        571 kB       1432 kB
cc-cedict          910967         29 MB       3927 kB       8945 kB
fd-ita-nor          11186        183 kB        493 kB       1276 kB
fd-epo-eng         190437       3296 kB       2794 kB       8145 kB
fd-swh-pol           1325         16 kB         22 kB         57 kB
fd-deu-cat          14070        250 kB        904 kB       2210 kB
fd-deu-bul          10225        174 kB        624 kB       1519 kB
fd-pol-deu          25221        462 kB       1399 kB       3709 kB
fd-deu-ind          16013        279 kB        938 kB       2344 kB
fd-nld-spa          27328        478 kB       1032 kB       2637 kB
fd-slk-eng            833         11 kB         13 kB         28 kB
fd-zho-lit          85998       1351 kB       2580 kB       7992 kB
fd-ita-rus          13594        230 kB        644 kB       1699 kB
fd-eng-por          15865        250 kB        280 kB        741 kB
fd-ita-cat          21293        362 kB        880 kB       2344 kB
fd-ell-deu          10715        265 kB        282 kB        745 kB
fd-cat-por          11406        185 kB        395 kB       1189 kB
fd-eng-nld           7720        119 kB        165 kB        415 kB
fd-swe-jpn          13039        214 kB        619 kB       1451 kB
fd-ita-deu           2930         40 kB         50 kB        119 kB
fd-eng-lit           6260         94 kB        206 kB        516 kB
fd-fin-gle          14724        259 kB        687 kB       1720 kB
fd-pol-tur          12233        213 kB        675 kB       1754 kB
fd-spa-cat          10086        172 kB        461 kB       1169 kB
fd-eng-ell          20990        357 kB        415 kB       1206 kB
fd-eng-lat           3032         40 kB         39 kB         96 kB
fd-ell-nor          10757        257 kB        256 kB        707 kB
fd-lat-deu          12279        190 kB        161 kB        519 kB
fd-zho-mlg          75106       1178 kB       2070 kB       6677 kB
fd-eng-hrv          59200       1239 kB       1398 kB       3985 kB
fd-nld-fin          11961        201 kB        546 kB       1357 kB
fd-jpn-deu         242817       5297 kB       6377 kB         28 MB
fd-cat-fra          21114        376 kB        736 kB       2212 kB
fd-lit-eng           7037        117 kB        179 kB        497 kB
fd-fin-ind          12722        222 kB        595 kB       1499 kB
fd-eng-hin          25648        420 kB       1198 kB       3616 kB
fd-rus-spa          17984        457 kB        712 kB       2164 kB
fd-gle-eng           1191         16 kB         18 kB         43 kB
fd-eng-ind          12791        220 kB        940 kB       2321 kB
fd-deu-kur          22573        376 kB        237 kB        843 kB
fd-eng-cat          33447        583 kB       2227 kB       5661 kB
fd-eng-nor          11461        191 kB        826 kB       2030 kB
fd-deu-tur          36225        585 kB        355 kB       1392 kB
fd-eng-zho          24248        407 kB       1741 kB       4141 kB
fd-cat-eng          22970        409 kB        788 kB       2392 kB
fd-fra-rus          22010        396 kB        813 kB       2140 kB
fd-eng-fra           8805        128 kB        135 kB        340 kB
fd-swe-lit          10677        170 kB        459 kB       1139 kB
fd-eng-spa          58636       1059 kB       3962 kB      10055 kB
fd-hrv-eng          79814       1816 kB       1633 kB       4819 kB
fd-ell-fra          30215        788 kB        715 kB       2067 kB
fd-eng-ara          87430       1413 kB       1094 kB       3871 kB
fd-cat-fin          10030        161 kB        366 kB       1047 kB
fd-srp-eng            401          6 kB          7 kB         16 kB
fd-eng-ita           4525         59 kB         59 kB        157 kB
fd-pol-fin          17512        311 kB        955 kB       2506 kB
fd-fra-gle          11970        205 kB        464 kB       1167 kB
fd-kha-deu           1013         13 kB         12 kB         32 kB
fd-afr-deu           3806         52 kB         69 kB        179 kB
fd-nld-por          12507        210 kB        564 kB       1410 kB
fd-tur-cat          11822        190 kB        243 kB        613 kB
fd-eng-tur          36595        585 kB       1891 kB       4713 kB
fd-swh-eng           2681         34 kB         48 kB        138 kB
fd-fin-pol          14014        253 kB        676 kB       1699 kB
fd-fra-deu          45706        869 kB       1645 kB       4234 kB
fd-deu-lit          10288        177 kB        622 kB       1522 kB
fd-fin-eng          40586        817 kB       1785 kB       4846 kB
fd-swe-nor          17307        299 kB        724 kB       1857 kB
fd-spa-ast          49258        791 kB        555 kB       1823 kB
fd-nld-gle          17793        297 kB        735 kB       1851 kB
fd-fra-ita          62931       1207 kB       1689 kB       4775 kB
fd-swe-fin          16570        282 kB        732 kB       1836 kB
fd-fin-jpn          13914        249 kB        711 kB       1710 kB
fd-afr-eng           5135         72 kB         82 kB        213 kB
fd-ita-ell          19217        326 kB        883 kB       2330 kB
fd-eng-swe          42283        757 kB       2939 kB       7349 kB
fd-swe-cat          15308        254 kB        651 kB       1634 kB
fd-ell-rus          14715        368 kB        386 kB       1120 kB
fd-kur-eng           5214         68 kB         47 kB        144 kB
fd-fra-tur          10875        188 kB        417 kB       1032 kB
fd-fin-por          13918        249 kB        668 kB       1682 kB
fd-ara-eng          53002       1286 kB       1057 kB       3011 kB
fd-eng-afr           6403         85 kB         86 kB        232 kB
fd-deu-ita           4449         64 kB         61 kB        162 kB
fd-fra-fin          15266        277 kB        559 kB       1405 kB
fd-ita-spa          13753        234 kB        582 kB       1558 kB
fd-zho-rus         162078       2613 kB       7274 kB         23 MB
fd-zho-kur          57561        907 kB       1720 kB       5249 kB
fd-fin-ita          14165        255 kB        678 kB       1720 kB
fd-swe-fra          19814        336 kB        836 kB       2116 kB
fd-fin-spa          10324        180 kB        510 kB       1271 kB
english                 0          0 kB          0 kB          0 kB
trans                   0          0 kB          0 kB          0 kB
all                     0          0 kB          0 kB          0 kB

==== capabilities ====
auth:mime
==== END ====
