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
    && do { $serverinfo =~ s/^On pan\.alephnull\.com.*?[\n\r]+//s}
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
foldoc              15126        300 kB       2210 kB       5411 kB
easton               3968         64 kB       1077 kB       2648 kB
hitchcock            2619         34 kB         33 kB         85 kB
bouvier              6797        128 kB       2338 kB       6185 kB
devil                1008         15 kB        161 kB        374 kB
world02               280          5 kB       1543 kB       7172 kB
gaz2k-counties      12875        269 kB        280 kB       1502 kB
gaz2k-places        51361       1006 kB       1711 kB         13 MB
gaz2k-zips          33249        454 kB       2122 kB         15 MB
--exit--                0          0 kB          0 kB          0 kB
fd-tur-eng           1032         14 kB         11 kB         24 kB
fd-por-deu           8300        124 kB        110 kB        276 kB
fd-nld-eng          22753        378 kB        366 kB        991 kB
fd-eng-ara          87430       1404 kB        721 kB       2489 kB
fd-spa-eng           4508         67 kB         77 kB        190 kB
fd-eng-hun          89685       1907 kB       2159 kB       5876 kB
fd-ita-eng           3435         48 kB         37 kB         92 kB
fd-wel-eng            734          9 kB          7 kB         17 kB
fd-eng-nld           7720        119 kB        168 kB        446 kB
fd-fra-eng           8511        131 kB        138 kB        385 kB
fd-tur-deu            947         13 kB         11 kB         24 kB
fd-swe-eng           5226         71 kB         52 kB        128 kB
fd-nld-fra          16776        270 kB        249 kB        672 kB
fd-eng-swa           1458         18 kB         11 kB         37 kB
fd-deu-nld          12818        200 kB        192 kB        524 kB
fd-fra-deu           6120         90 kB        108 kB        275 kB
fd-eng-cro          59211       1220 kB        971 kB       2706 kB
fd-eng-ita           4525         59 kB         40 kB        108 kB
fd-eng-lat           3032         40 kB         39 kB        100 kB
fd-lat-eng           2311         31 kB         24 kB         62 kB
fd-fra-nld           9610        152 kB        195 kB        502 kB
fd-ita-deu           2929         40 kB         37 kB         87 kB
fd-eng-hin          25648        418 kB       1041 kB       3019 kB
fd-deu-eng          81627       1614 kB       1346 kB       4176 kB
fd-por-eng          10667        164 kB        125 kB        315 kB
fd-lat-deu           7342        107 kB        105 kB        365 kB
fd-jpn-deu            447          5 kB          6 kB         12 kB
fd-eng-deu          93283       1708 kB       1403 kB       4212 kB
fd-eng-scr            605          7 kB          8 kB         21 kB
fd-eng-rom            996         14 kB         12 kB         31 kB
fd-iri-eng           1191         16 kB         11 kB         28 kB
fd-cze-eng            494          6 kB          5 kB         11 kB
fd-scr-eng            401          6 kB          4 kB         11 kB
fd-eng-cze         150010       2482 kB       1463 kB       8478 kB
fd-eng-rus           1699         23 kB         26 kB         71 kB
fd-afr-deu           3806         52 kB         49 kB        129 kB
fd-eng-por          15854        248 kB        239 kB        634 kB
fd-hun-eng         139941       3344 kB       2245 kB       6184 kB
fd-eng-swe           5485         71 kB         75 kB        191 kB
fd-deu-ita           4460         64 kB         38 kB         99 kB
fd-cro-eng          79821       1791 kB       1016 kB       2899 kB
fd-dan-eng           4003         54 kB         43 kB        103 kB
fd-eng-tur          36595        580 kB       1687 kB       4214 kB
fd-eng-spa           5913         76 kB         81 kB        217 kB
fd-nld-deu          17230        278 kB        306 kB        827 kB
fd-deu-por           8748        130 kB        104 kB        270 kB
fd-swa-eng           1554         19 kB         13 kB         43 kB
fd-hin-eng          32971       1227 kB       1062 kB       3274 kB
fd-deu-fra           8174        120 kB         81 kB        216 kB
fd-eng-fra           8805        129 kB        137 kB        361 kB
fd-slo-eng            833         11 kB          9 kB         20 kB
fd-gla-deu            263          3 kB          4 kB          7 kB
fd-eng-wel           1066         13 kB         12 kB         31 kB
fd-eng-iri           1365         17 kB         18 kB         45 kB
english                 0          0 kB          0 kB          0 kB
trans                   0          0 kB          0 kB          0 kB
all                     0          0 kB          0 kB          0 kB

==== capabilities ====
auth:mime
==== END ====
