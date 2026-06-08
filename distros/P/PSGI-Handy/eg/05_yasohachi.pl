######################################################################
#
# 05_yasohachi.pl - Yaso-Hachi (rice-grain manager), no-database build
#
# Version (1): the DB::Handy dependency removed. This is the same
# Yaso-Hachi application as eg/05, expressed with exactly the same
# PSGI::Handy routing, Context (param/redirect/html) and HTTP::Handy
# delivery layer -- but the injected model is a plain in-memory store
# (RiceStore) instead of DB::Handy. Nothing outside the Perl core is
# loaded besides PSGI::Handy and HTTP::Handy.
#
# Because the model lives in memory, the data exists only for the life
# of the running process: it needs no temp directory and leaves nothing
# behind, but it also does not survive a restart. That trade is exactly
# what "remove the database" means here.
#
# The kanji for rice ("&#x7c73;") hides the figure 88 ("eight-ten-eight"),
# the traditional count of labours from seedbed to table. Each grain
# gets a 160-bit Rice-ID and 88 status rows; the UI tracks progress.
#
# Run: perl -Ilib eg/05_yasohachi.pl
# Then open http://127.0.0.1:8080/ to register and track grains.
#
# Demonstrates:
#   PSGI::Handy new(db=>...)/get/post/to_app with literal-before-:param
#   route ordering, Context db/param/html/redirect, a not_found handler,
#   an injected in-memory model (no SQL), and US-ASCII source that renders
#   Japanese via &#xNNNN; numeric character references.
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";

use PSGI::Handy;
use HTTP::Handy;   # delivery layer (any PSGI server works)

######################################################################
# Inlined model classes (kept in-file so the example is one script).
# All are written to run on Perl 5.005_03 and later.
######################################################################

######################################################################
# RiceID - 160-bit (40 hex chars) unique id for a single grain.
#   [48-bit timestamp from 12000 BCE][12-bit ver/variant/flags][100-bit random]
# Big-integer math is done with string arithmetic, so no bignum is needed.
######################################################################
package RiceID;

my $RICE_EPOCH_OFFSET_MS  = '151214342400000';   # 1750166 days * 86400000
my $VERSION_VARIANT_FLAGS = '1a0';               # 12 bits as 3 hex chars

sub new { return bless {}, $_[0] }

sub generate {
    my ($self) = @_;
    my $ts_ms   = _current_ms();
    my $rice_ms = _str_add("$ts_ms", $RICE_EPOCH_OFFSET_MS);
    my $ts_hex  = _ms_to_hex48($rice_ms);
    my $rand    = _random_hex(25);               # 12 + 3 + 25 = 40 hex
    return $ts_hex . $VERSION_VARIANT_FLAGS . $rand;
}

sub is_valid {
    my ($self, $id) = @_;
    return 0 unless defined $id;
    return 0 unless length($id) == 40;
    return 0 unless $id =~ /^[0-9a-f]{40}$/;
    return 0 unless substr($id, 12, 3) =~ /^1a[0-9a-f]$/;
    return 1;
}

sub _current_ms {
    my $ms;
    eval { require Time::HiRes; $ms = int(Time::HiRes::time() * 1000); };
    if ($@) { $ms = time() * 1000 + int(rand(1000)); }
    return $ms;
}

sub _str_add {
    my ($a, $b) = @_;
    my @da = reverse split(//, $a);
    my @db = reverse split(//, $b);
    my @r;
    my $carry = 0;
    my $len = length($a) > length($b) ? length($a) : length($b);
    my $i;
    for ($i = 0; $i <= $len; $i++) {
        my $d = ($da[$i] || 0) + ($db[$i] || 0) + $carry;
        $carry = int($d / 10);
        push @r, $d % 10;
    }
    push @r, $carry if $carry;
    my $s = join('', reverse @r);
    $s =~ s/^0+//;
    return $s eq '' ? '0' : $s;
}

sub _ms_to_hex48 {
    my ($dec) = @_;
    my $hex = _dec_to_hex($dec);
    return substr(('0' x 12) . $hex, -12);
}

sub _dec_to_hex {
    my ($dec) = @_;
    return '0' unless defined $dec && $dec ne '' && $dec ne '0';
    return sprintf('%x', $dec) if length($dec) <= 15;
    my $hex = '';
    my $n   = $dec;
    while ($n ne '0') {
        my ($q, $rem) = _divmod($n, 16);
        $hex = sprintf('%x', $rem) . $hex;
        $n   = $q;
    }
    return $hex eq '' ? '0' : $hex;
}

sub _divmod {
    my ($n, $d) = @_;
    my $q = '';
    my $r = 0;
    my $ch;
    for $ch (split(//, $n)) {
        $r = $r * 10 + $ch;
        $q .= int($r / $d);
        $r = $r % $d;
    }
    $q =~ s/^0+//;
    return ($q eq '' ? '0' : $q, $r);
}

sub _random_hex {
    my ($len) = @_;
    my $hex = '';
    while (length($hex) < $len) {
        $hex .= sprintf('%08x', int(rand(0xFFFFFFFF + 1)));
    }
    return substr($hex, 0, $len);
}

######################################################################
# RiceProcess - the canonical list of the 88 cultivation steps.
# Step names and category labels are stored as US-ASCII numeric
# character references (&#xNNNN;) so the source file stays US-ASCII
# while the browser shows Japanese. They are therefore emitted raw
# (already-safe HTML) and never passed through the h() escaper.
# Status codes: 0 = not started, 1 = in progress, 2 = completed.
######################################################################
package RiceProcess;

my @PROCESSES = (
    [ 1,  'field_survey',           '&#x7530;&#x3093;&#x307c;&#x306e;&#x571f;&#x58cc;&#x8abf;&#x67fb;',                '&#x82d7;&#x3065;&#x304f;&#x308a;&#x6e96;&#x5099;'],
    [ 2,  'seed_selection',         '&#x7a2e;&#x3082;&#x307f;&#x306e;&#x9078;&#x5225;&#xff08;&#x5869;&#x6c34;&#x9078;&#xff09;',          '&#x82d7;&#x3065;&#x304f;&#x308a;&#x6e96;&#x5099;'],
    [ 3,  'seed_disinfection',      '&#x7a2e;&#x3082;&#x307f;&#x306e;&#x6d88;&#x6bd2;&#xff08;&#x6e29;&#x6e6f;&#x6d88;&#x6bd2;&#x7b49;&#xff09;',      '&#x82d7;&#x3065;&#x304f;&#x308a;&#x6e96;&#x5099;'],
    [ 4,  'seed_soaking',           '&#x7a2e;&#x3082;&#x307f;&#x306e;&#x6d78;&#x7a2e;',                    '&#x82d7;&#x3065;&#x304f;&#x308a;&#x6e96;&#x5099;'],
    [ 5,  'seed_germination',       '&#x50ac;&#x82bd;&#xff08;&#x82bd;&#x51fa;&#x3057;&#xff09;',                  '&#x82d7;&#x3065;&#x304f;&#x308a;&#x6e96;&#x5099;'],
    [ 6,  'nursery_preparation',    '&#x80b2;&#x82d7;&#x5e8a;&#x306e;&#x6e96;&#x5099;&#x30fb;&#x6574;&#x5730;',              '&#x82d7;&#x3065;&#x304f;&#x308a;&#x6e96;&#x5099;'],
    [ 7,  'soil_mix_preparation',   '&#x80b2;&#x82d7;&#x57f9;&#x571f;&#x306e;&#x8abf;&#x88fd;',                  '&#x80b2;&#x82d7;'],
    [ 8,  'sowing',                 '&#x64ad;&#x7a2e;&#xff08;&#x305f;&#x306d;&#x307e;&#x304d;&#xff09;',                '&#x80b2;&#x82d7;'],
    [ 9,  'seedling_watering',      '&#x80b2;&#x82d7;&#x4e2d;&#x306e;&#x704c;&#x6c34;&#x30fb;&#x6c34;&#x7ba1;&#x7406;',            '&#x80b2;&#x82d7;'],
    [10,  'seedling_temperature',   '&#x80b2;&#x82d7;&#x30cf;&#x30a6;&#x30b9;&#x5185;&#x306e;&#x6e29;&#x5ea6;&#x7ba1;&#x7406;',          '&#x80b2;&#x82d7;'],
    [11,  'winter_plowing',         '&#x51ac;&#x8d77;&#x3053;&#x3057;&#xff08;&#x79cb;&#x8015;&#xff09;',                '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [12,  'soil_amendment',         '&#x571f;&#x58cc;&#x6539;&#x826f;&#x8cc7;&#x6750;&#x306e;&#x65bd;&#x7528;',              '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [13,  'basal_fertilizer',       '&#x5143;&#x80a5;&#x306e;&#x65bd;&#x7528;',                      '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [14,  'irrigation_check',       '&#x7528;&#x6c34;&#x8def;&#x306e;&#x70b9;&#x691c;&#x30fb;&#x88dc;&#x4fee;',              '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [15,  'flooding',               '&#x4ee3;&#x304b;&#x304d;&#x524d;&#x306e;&#x5165;&#x6c34;',                  '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [16,  'primary_tillage',        '&#x8352;&#x4ee3;&#x304b;&#x304d;&#xff08;&#x4e00;&#x6b21;&#x4ee3;&#x304b;&#x304d;&#xff09;',          '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [17,  'secondary_tillage',      '&#x4ed5;&#x4e0a;&#x3052;&#x4ee3;&#x304b;&#x304d;&#xff08;&#x4e8c;&#x6b21;&#x4ee3;&#x304b;&#x304d;&#xff09;',      '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [18,  'leveling',               '&#x7530;&#x9762;&#x5747;&#x5e73;&#x4f5c;&#x696d;',                    '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [19,  'water_level_control',    '&#x6c34;&#x4f4d;&#x8abf;&#x6574;',                        '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [20,  'weed_early_treatment',   '&#x4ee3;&#x304b;&#x304d;&#x5f8c;&#x306e;&#x96d1;&#x8349;&#x6291;&#x5236;',              '&#x571f;&#x3065;&#x304f;&#x308a;'],
    [21,  'transplanting_plan',     '&#x7530;&#x690d;&#x3048;&#x306e;&#x8a08;&#x753b;&#x30fb;&#x30b9;&#x30b1;&#x30b8;&#x30e5;&#x30fc;&#x30eb;&#x78ba;&#x8a8d;',  '&#x7530;&#x690d;&#x3048;'],
    [22,  'seedling_transport',     '&#x82d7;&#x306e;&#x7530;&#x3093;&#x307c;&#x3078;&#x306e;&#x904b;&#x642c;',              '&#x7530;&#x690d;&#x3048;'],
    [23,  'transplanting',          '&#x7530;&#x690d;&#x3048;&#xff08;&#x6a5f;&#x68b0;&#x307e;&#x305f;&#x306f;&#x624b;&#x690d;&#x3048;&#xff09;',      '&#x7530;&#x690d;&#x3048;'],
    [24,  'gap_filling',            '&#x6b20;&#x682a;&#x306e;&#x88dc;&#x690d;',                      '&#x7530;&#x690d;&#x3048;'],
    [25,  'post_transplant_water',  '&#x6d3b;&#x7740;&#x4fc3;&#x9032;&#x306e;&#x305f;&#x3081;&#x306e;&#x6c34;&#x7ba1;&#x7406;',          '&#x7530;&#x690d;&#x3048;'],
    [26,  'shallow_water_keep',     '&#x5206;&#x3052;&#x3064;&#x4fc3;&#x9032;&#x306e;&#x305f;&#x3081;&#x306e;&#x6d45;&#x6c34;&#x7ba1;&#x7406;',      '&#x7530;&#x690d;&#x3048;'],
    [27,  'row_spacing_check',      '&#x6761;&#x9593;&#x30fb;&#x682a;&#x9593;&#x306e;&#x78ba;&#x8a8d;',                '&#x7530;&#x690d;&#x3048;'],
    [28,  'early_weed_control',     '&#x521d;&#x671f;&#x9664;&#x8349;',                        '&#x7530;&#x690d;&#x3048;'],
    [29,  'tillering_water',        '&#x5206;&#x3052;&#x3064;&#x671f;&#x306e;&#x6c34;&#x7ba1;&#x7406;',                '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [30,  'mid_season_drainage',    '&#x4e2d;&#x5e72;&#x3057;&#xff08;&#x571f;&#x58cc;&#x786c;&#x5316;&#xff09;',              '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [31,  'intermittent_irrigation', '&#x9593;&#x65ad;&#x704c;&#x6f11;',                        '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [32,  'topdress_fertilizer',    '&#x8ffd;&#x80a5;&#x306e;&#x65bd;&#x7528;',                      '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [33,  'panicle_fertilizer',     '&#x7a42;&#x80a5;&#x306e;&#x65bd;&#x7528;',                      '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [34,  'disease_scouting',       '&#x75c5;&#x5bb3;&#x866b;&#x306e;&#x5de1;&#x56de;&#x8abf;&#x67fb;',                '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [35,  'fungicide_application',  '&#x6bba;&#x83cc;&#x5264;&#x6563;&#x5e03;&#xff08;&#x3044;&#x3082;&#x3061;&#x75c5;&#x7b49;&#xff09;',        '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [36,  'insecticide_application', '&#x6bba;&#x866b;&#x5264;&#x6563;&#x5e03;&#xff08;&#x30ab;&#x30e1;&#x30e0;&#x30b7;&#x7b49;&#xff09;',        '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [37,  'weed_management',        '&#x9664;&#x8349;&#x5264;&#x6563;&#x5e03;&#x307e;&#x305f;&#x306f;&#x624b;&#x53d6;&#x308a;&#x9664;&#x8349;',      '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [38,  'growth_monitoring',      '&#x8349;&#x4e08;&#x30fb;&#x830e;&#x6570;&#x8abf;&#x67fb;',                  '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [39,  'leaf_color_check',       '&#x8449;&#x8272;&#x8a3a;&#x65ad;&#xff08;SPAD&#x8a08;&#xff09;',              '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [40,  'panicle_formation_check', '&#x5e7c;&#x7a42;&#x5f62;&#x6210;&#x671f;&#x306e;&#x78ba;&#x8a8d;',                '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [41,  'heading_water',          '&#x51fa;&#x7a42;&#x671f;&#x306e;&#x6df1;&#x6c34;&#x7ba1;&#x7406;',                '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [42,  'heading_confirmation',   '&#x51fa;&#x7a42;&#x65e5;&#x306e;&#x78ba;&#x8a8d;&#x30fb;&#x8a18;&#x9332;',              '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [43,  'ripening_water',         '&#x767b;&#x719f;&#x671f;&#x306e;&#x6c34;&#x7ba1;&#x7406;',                  '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [44,  'final_drainage',         '&#x53ce;&#x7a6b;&#x524d;&#x306e;&#x843d;&#x6c34;&#xff08;&#x6700;&#x7d42;&#x843d;&#x6c34;&#xff09;',        '&#x683d;&#x57f9;&#x7ba1;&#x7406;'],
    [45,  'harvest_timing',         '&#x9069;&#x671f;&#x53ce;&#x7a6b;&#x306e;&#x5224;&#x65ad;',                  '&#x53ce;&#x7a6b;'],
    [46,  'pre_harvest_scouting',   '&#x53ce;&#x7a6b;&#x524d;&#x306e;&#x5703;&#x5834;&#x898b;&#x56de;&#x308a;',              '&#x53ce;&#x7a6b;'],
    [47,  'combine_preparation',    '&#x30b3;&#x30f3;&#x30d0;&#x30a4;&#x30f3;&#x307e;&#x305f;&#x306f;&#x938c;&#x306e;&#x6e96;&#x5099;',        '&#x53ce;&#x7a6b;'],
    [48,  'harvesting',             '&#x5208;&#x308a;&#x53d6;&#x308a;&#x30fb;&#x53ce;&#x7a6b;',                  '&#x53ce;&#x7a6b;'],
    [49,  'threshing',              '&#x8131;&#x7a40;&#xff08;&#x30b3;&#x30f3;&#x30d0;&#x30a4;&#x30f3;&#x5185;&#xff09;',            '&#x53ce;&#x7a6b;'],
    [50,  'straw_handling',         '&#x7a32;&#x308f;&#x3089;&#x306e;&#x51e6;&#x7406;&#x30fb;&#x88c1;&#x65ad;',              '&#x53ce;&#x7a6b;'],
    [51,  'rough_rice_transport',   '&#x7c7e;&#x306e;&#x5703;&#x5834;&#x304b;&#x3089;&#x306e;&#x642c;&#x51fa;',              '&#x53ce;&#x7a6b;'],
    [52,  'drying',                 '&#x4e7e;&#x71e5;&#xff08;&#x4e7e;&#x71e5;&#x6a5f;&#x307e;&#x305f;&#x306f;&#x5929;&#x65e5;&#x5e72;&#x3057;&#xff09;',    '&#x53ce;&#x7a6b;'],
    [53,  'moisture_check',         '&#x6c34;&#x5206;&#x6e2c;&#x5b9a;&#xff08;&#x76ee;&#x6a19;15%&#x4ee5;&#x4e0b;&#xff09;',         '&#x53ce;&#x7a6b;'],
    [54,  'rough_rice_storage',     '&#x7c7e;&#x306e;&#x4e00;&#x6642;&#x4fdd;&#x7ba1;',                    '&#x53ce;&#x7a6b;'],
    [55,  'hulling',                '&#x7c7e;&#x647a;&#x308a;&#xff08;&#x3082;&#x307f;&#x6bbb;&#x9664;&#x53bb;&#xff09;',            '&#x8abf;&#x88fd;&#x30fb;&#x52a0;&#x5de5;'],
    [56,  'brown_rice_sorting',     '&#x7384;&#x7c73;&#x306e;&#x9078;&#x5225;&#xff08;&#x7570;&#x7269;&#x9664;&#x53bb;&#xff09;',          '&#x8abf;&#x88fd;&#x30fb;&#x52a0;&#x5de5;'],
    [57,  'brown_rice_inspection',  '&#x7384;&#x7c73;&#x306e;&#x54c1;&#x8cea;&#x691c;&#x67fb;',                  '&#x8abf;&#x88fd;&#x30fb;&#x52a0;&#x5de5;'],
    [58,  'brown_rice_storage',     '&#x7384;&#x7c73;&#x306e;&#x4fdd;&#x7ba1;&#xff08;&#x4f4e;&#x6e29;&#x5009;&#x5eab;&#xff09;',          '&#x8abf;&#x88fd;&#x30fb;&#x52a0;&#x5de5;'],
    [59,  'polishing',              '&#x7cbe;&#x7c73;&#xff08;&#x7384;&#x7c73;&#x304b;&#x3089;&#x767d;&#x7c73;&#x3078;&#xff09;',          '&#x8abf;&#x88fd;&#x30fb;&#x52a0;&#x5de5;'],
    [60,  'polished_rice_sorting',  '&#x767d;&#x7c73;&#x306e;&#x9078;&#x5225;&#x30fb;&#x7b49;&#x7d1a;&#x5206;&#x3051;',            '&#x8abf;&#x88fd;&#x30fb;&#x52a0;&#x5de5;'],
    [61,  'packaging',              '&#x888b;&#x8a70;&#x3081;&#x30fb;&#x8a08;&#x91cf;',                    '&#x8abf;&#x88fd;&#x30fb;&#x52a0;&#x5de5;'],
    [62,  'labeling',               '&#x30e9;&#x30d9;&#x30eb;&#x8cbc;&#x4ed8;&#x30fb;&#x8868;&#x793a;&#x78ba;&#x8a8d;',            '&#x8abf;&#x88fd;&#x30fb;&#x52a0;&#x5de5;'],
    [63,  'lot_management',         '&#x30ed;&#x30c3;&#x30c8;&#x7ba1;&#x7406;&#x30fb;&#x30c8;&#x30ec;&#x30fc;&#x30b5;&#x30d3;&#x30ea;&#x30c6;&#x30a3;',    '&#x54c1;&#x8cea;&#x7ba1;&#x7406;'],
    [64,  'sensory_evaluation',     '&#x98df;&#x5473;&#x30fb;&#x98df;&#x3079;&#x5fc3;&#x5730;&#x306e;&#x691c;&#x67fb;',            '&#x54c1;&#x8cea;&#x7ba1;&#x7406;'],
    [65,  'residue_inspection',     '&#x8fb2;&#x85ac;&#x6b8b;&#x7559;&#x691c;&#x67fb;',                    '&#x54c1;&#x8cea;&#x7ba1;&#x7406;'],
    [66,  'arsenic_check',          '&#x30ab;&#x30c9;&#x30df;&#x30a6;&#x30e0;&#x30fb;&#x91cd;&#x91d1;&#x5c5e;&#x691c;&#x67fb;',          '&#x54c1;&#x8cea;&#x7ba1;&#x7406;'],
    [67,  'storage_temperature',    '&#x4fdd;&#x7ba1;&#x6e29;&#x5ea6;&#x30fb;&#x6e7f;&#x5ea6;&#x306e;&#x7ba1;&#x7406;',            '&#x54c1;&#x8cea;&#x7ba1;&#x7406;'],
    [68,  'inventory_management',   '&#x5728;&#x5eab;&#x30fb;&#x51fa;&#x8377;&#x7ba1;&#x7406;',                  '&#x54c1;&#x8cea;&#x7ba1;&#x7406;'],
    [69,  'shipping',               '&#x51fa;&#x8377;&#x30fb;&#x914d;&#x9001;&#x624b;&#x914d;',                  '&#x6d41;&#x901a;'],
    [70,  'cold_chain',             '&#x30b3;&#x30fc;&#x30eb;&#x30c9;&#x30c1;&#x30a7;&#x30fc;&#x30f3;&#x7ba1;&#x7406;',            '&#x6d41;&#x901a;'],
    [71,  'retail_display',         '&#x5c0f;&#x58f2;&#x5e97;&#x3067;&#x306e;&#x9673;&#x5217;&#x7ba1;&#x7406;',              '&#x6d41;&#x901a;'],
    [72,  'expiry_management',      '&#x8cde;&#x5473;&#x671f;&#x9650;&#x306e;&#x7ba1;&#x7406;',                  '&#x6d41;&#x901a;'],
    [73,  'purchase',               '&#x6d88;&#x8cbb;&#x8005;&#x306b;&#x3088;&#x308b;&#x8cfc;&#x5165;&#x30fb;&#x6301;&#x3061;&#x5e30;&#x308a;',      '&#x98df;&#x5353;'],
    [74,  'home_storage',           '&#x5bb6;&#x5ead;&#x3067;&#x306e;&#x4fdd;&#x7ba1;',                    '&#x98df;&#x5353;'],
    [75,  'rice_measuring',         '&#x8a08;&#x91cf;&#x30fb;&#x6d17;&#x7c73;',                      '&#x98df;&#x5353;'],
    [76,  'soaking',                '&#x6d78;&#x6c34;&#xff08;&#x5438;&#x6c34;&#xff09;',                    '&#x98df;&#x5353;'],
    [77,  'cooking',                '&#x708a;&#x98ef;',                            '&#x98df;&#x5353;'],
    [78,  'steaming',               '&#x84b8;&#x3089;&#x3057;',                          '&#x98df;&#x5353;'],
    [79,  'serving',                '&#x304a;&#x8336;&#x7897;&#x306b;&#x3088;&#x305d;&#x3046;',                  '&#x98df;&#x5353;'],
    [80,  'eating',                 '&#x98df;&#x3079;&#x308b;&#x2015;&#x2015;&#x3044;&#x305f;&#x3060;&#x304d;&#x307e;&#x3059;',            '&#x98df;&#x5353;'],
    [81,  'waste_reduction',        '&#x98df;&#x54c1;&#x30ed;&#x30b9;&#x30bc;&#x30ed;&#x3078;&#x306e;&#x53d6;&#x308a;&#x7d44;&#x307f;',        '&#x6301;&#x7d9a;&#x53ef;&#x80fd;&#x6027;'],
    [82,  'compost_return',         '&#x751f;&#x3054;&#x307f;&#x306e;&#x5806;&#x80a5;&#x5316;',                  '&#x6301;&#x7d9a;&#x53ef;&#x80fd;&#x6027;'],
    [83,  'seed_saving',            '&#x6b21;&#x4e16;&#x4ee3;&#x3078;&#x306e;&#x7a2e;&#x5b50;&#x4fdd;&#x5b58;',              '&#x6301;&#x7d9a;&#x53ef;&#x80fd;&#x6027;'],
    [84,  'field_record',           '&#x5703;&#x5834;&#x8a18;&#x9332;&#x306e;&#x4f5c;&#x6210;&#x30fb;&#x4fdd;&#x7ba1;',            '&#x8a18;&#x9332;'],
    [85,  'harvest_report',         '&#x53ce;&#x91cf;&#x30fb;&#x54c1;&#x8cea;&#x306e;&#x5831;&#x544a;',                '&#x8a18;&#x9332;'],
    [86,  'research_feedback',      '&#x6539;&#x5584;&#x70b9;&#x306e;&#x691c;&#x8a0e;&#x30fb;&#x7814;&#x7a76;&#x30d5;&#x30a3;&#x30fc;&#x30c9;&#x30d0;&#x30c3;&#x30af;', '&#x8a18;&#x9332;'],
    [87,  'gratitude',              '&#x8fb2;&#x5bb6;&#x30fb;&#x8fb2;&#x696d;&#x5f93;&#x4e8b;&#x8005;&#x3078;&#x306e;&#x611f;&#x8b1d;',        '&#x611f;&#x8b1d;'],
    [88,  'grain_completion',       '&#x4e00;&#x7c92;&#x306e;&#x7c73;&#x306e;&#x65c5;&#x3001;&#x5b8c;&#x7d50;',              '&#x611f;&#x8b1d;'],
);

sub new { return bless { processes => \@PROCESSES }, $_[0] }

sub all {
    my ($self) = @_;
    my @r;
    my $p;
    for $p (@{ $self->{processes} }) {
        push @r, { number => $p->[0], key => $p->[1],
                   name => $p->[2], category => $p->[3] };
    }
    return [ @r ];
}

######################################################################
# RiceStore - the in-memory model injected in place of DB::Handy.
#
# Holds every grain and its 88 status rows in plain Perl hashes for the
# lifetime of the process. The public methods mirror just the slice of
# behaviour the application needs, so the route handlers stay as small
# as they were over a real database. Written for Perl 5.005_03+.
#   status codes: 0 = not started, 1 = in progress, 2 = completed.
######################################################################
package RiceStore;

sub new {
    return bless { grains => {}, status => {}, seq => 0 }, $_[0];
}

# insert(\%grain) -- store the grain and seed its 88 status rows (all 0).
sub insert {
    my ($self, $g) = @_;
    $self->{seq}++;
    my %row = %$g;
    $row{_seq} = $self->{seq};
    $self->{grains}{ $row{rice_id} } = { %row };
    my %st;
    my $step;
    for $step (@{ RiceProcess->new->all }) { $st{ $step->{number} } = 0 }
    $self->{status}{ $row{rice_id} } = { %st };
    return 1;
}

# all() -- every grain as an array reference, newest first.
sub all {
    my ($self) = @_;
    my @g = sort { $b->{_seq} <=> $a->{_seq} } values %{ $self->{grains} };
    my @copy;
    my $g;
    for $g (@g) { push @copy, { %$g } }
    return [ @copy ];
}

# get($id) -- one grain as a hash reference, or undef.
sub get {
    my ($self, $id) = @_;
    my $g = $self->{grains}{$id};
    return undef unless defined $g;
    return { %$g };
}

# status_rows($id) -- the 88 status rows ordered by step number, each a
# hash reference like the rows a SELECT would have returned.
sub status_rows {
    my ($self, $id) = @_;
    my $st = $self->{status}{$id} || {};
    my @rows;
    my $step;
    for $step (@{ RiceProcess->new->all }) {
        my $no = $step->{number};
        push @rows, {
            step_no  => $no,
            step_key => $step->{key},
            status   => (defined $st->{$no} ? $st->{$no} : 0),
        };
    }
    return [ @rows ];
}

# count_done($id) -- how many of the 88 steps are completed (status 2).
sub count_done {
    my ($self, $id) = @_;
    my $st = $self->{status}{$id} || {};
    my $done = 0;
    my $no;
    for $no (keys %$st) {
        $done++ if defined $st->{$no} && $st->{$no} == 2;
    }
    return $done;
}

# update_status($id, $step_no, $value) -- set one step's status.
sub update_status {
    my ($self, $id, $no, $v) = @_;
    return 0 unless defined $self->{status}{$id};
    $self->{status}{$id}{$no} = $v;
    return 1;
}

# remove($id) -- drop the grain and its status rows.
sub remove {
    my ($self, $id) = @_;
    delete $self->{grains}{$id};
    delete $self->{status}{$id};
    return 1;
}

######################################################################
# Back to the application.
######################################################################
package main;

# --- small helpers --------------------------------------------------

# HTML-escape a user-supplied value (process names are NOT passed here;
# they are pre-encoded numeric character references).
sub h {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
}

sub now {
    my @t = localtime(time);
    return sprintf('%04d-%02d-%02d %02d:%02d:%02d',
                   $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
}

# Validate the extended date: optional '-', 1-7 digit year, optional
# -MM-DD. Returns a cleaned string, or '' if empty/invalid.
sub validate_date {
    my ($s) = @_;
    $s = '' unless defined $s;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return '' if $s eq '';
    return '' unless $s =~ /^(-?\d{1,7})(?:-(\d{2})-(\d{2}))?$/;
    my ($year, $mm, $dd) = ($1, $2, $3);
    return '' if $year < -12000 || $year > 1000000;
    if (defined $mm) {
        return '' if $mm < 1 || $mm > 12;
        return '' if $dd < 1 || $dd > 31;
        return sprintf('%s-%02d-%02d', $year, $mm, $dd);
    }
    return "$year";
}

# Render a stored planted_on string as Japanese (numeric entities).
sub format_planted_on {
    my ($s) = @_;
    return '' unless defined $s && $s ne '';
    if ($s =~ /^(-?)(\d+)-(\d+)-(\d+)$/) {
        my ($neg, $y, $mm, $dd) = ($1, $2, int($3), int($4));
        return sprintf('&#x7d00;&#x5143;&#x524d;%d&#x5e74; %d&#x6708;%d&#x65e5;', $y, $mm, $dd)
            if $neg eq '-';
        return sprintf('%d&#x5e74; %d&#x6708;%d&#x65e5;', $y, $mm, $dd);
    }
    if ($s =~ /^(-?)(\d+)$/) {
        my ($neg, $y) = ($1, $2);
        return sprintf('&#x7d00;&#x5143;&#x524d;%d&#x5e74;', $y) if $neg eq '-';
        return sprintf('%d&#x5e74;', $y);
    }
    return h($s);
}

# Page chrome shared by every view.
sub layout {
    my ($title, $content) = @_;
    return <<"HTML";
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>$title - Yaso-Hachi</title>
<style>
body{font-family:sans-serif;max-width:960px;margin:0 auto;padding:16px;background:#fffdf5}
h1{color:#5a3e00;border-bottom:2px solid #c8a84b;padding-bottom:6px}
h2{color:#7a5a00;margin-top:20px}
nav{margin-bottom:12px}
nav a{margin-right:14px;color:#5a7000;text-decoration:none;font-weight:bold}
table.data{border-collapse:collapse;width:100%}
table.data th,table.data td{border:1px solid #c8a84b;padding:6px 10px;text-align:left}
table.data th{background:#f5eacc}
table.data tr:hover td{background:#fffbee}
.btn{display:inline-block;padding:6px 14px;background:#5a3e00;color:#fff;
     text-decoration:none;border:none;cursor:pointer;border-radius:3px;font-size:14px}
.btn-sm{padding:3px 8px;font-size:12px}
.btn-del{background:#8b1a1a}
.form-row{margin-top:10px}
.form-row label{font-weight:bold;display:block;margin-bottom:3px}
.form-row input,.form-row textarea{
    width:100%;padding:6px;box-sizing:border-box;
    border:1px solid #c8a84b;border-radius:3px}
.date-hint{font-size:11px;color:#888;margin-top:2px}
.bar-wrap{background:#e8d8a0;border-radius:4px;height:13px;
          width:180px;display:inline-block;vertical-align:middle}
.bar{background:#5a8a00;height:13px;border-radius:4px}
.step-row{display:flex;gap:6px;align-items:center;padding:4px 2px;
          border-bottom:1px solid #ede0c0}
.step-no{width:28px;text-align:right;color:#aaa;font-size:12px}
.step-name{flex:1;font-size:13px;color:#3a2800}
.step-sel select{width:110px;font-size:13px}
.section-head{background:#f0e8c0;padding:4px 8px;margin:8px 0 2px;
              font-weight:bold;font-size:13px;color:#5a3e00;border-radius:3px}
</style>
</head>
<body>
<h1>&#x7c73; Yaso-Hachi &#x516b;&#x5341;&#x516b;</h1>
<nav>
<a href="/">&#x4e00;&#x89a7;</a>
<a href="/grain/new">+ &#x65b0;&#x898f;&#x767b;&#x9332;</a>
</nav>
<hr>
$content
</body>
</html>
HTML
}

# --- model: a brand-new in-memory store (no files, no temp directory) ---
my $store = RiceStore->new;

######################################################################
# Application: routes are registered literal-before-:param so that
# "/grain/new" and "/grain/create" win over "/grain/:id".
######################################################################
my $app = PSGI::Handy->new(
    db        => $store,
    not_found => sub {
        my $c = shift;
        return $c->html(
            layout('404', '<h2>404 Not Found</h2><p>'
                 . h($c->req->path) . '</p>'), 404);
    },
);

# GET / -- list every grain with its completion bar.
$app->get('/', sub {
    my $c   = shift;
    my $grains = $c->db->all;

    my $rows = '';
    my $g;
    for $g (@$grains) {
        my $id   = $g->{rice_id};
        my $d    = $c->db->count_done($id);
        my $pct  = int($d / 88 * 100);
        $rows .= '<tr>'
               . '<td><a href="/grain/' . $id . '"><code>'
               . substr($id, 0, 12) . '...</code></a></td>'
               . '<td>' . h($g->{variety})  . '</td>'
               . '<td>' . h($g->{grower})   . '</td>'
               . '<td>' . h($g->{location}) . '</td>'
               . '<td>' . format_planted_on($g->{planted_on}) . '</td>'
               . '<td>'
               . "<span class='bar-wrap'><span class='bar' style='width:${pct}%'></span></span>"
               . " ${d}/88 (${pct}%)</td>"
               . '<td><a class="btn btn-sm" href="/grain/' . $id
               . '">&#x8a73;&#x7d30;</a></td>'
               . "</tr>\n";
    }
    $rows = '<tr><td colspan="7">&#x767b;&#x9332;&#x30c7;&#x30fc;&#x30bf;&#x306a;&#x3057;</td></tr>'
        if $rows eq '';

    my $body = "<h2>&#x304a;&#x7c73;&#x4e00;&#x7c92;&#x4e00;&#x89a7;</h2>\n"
             . "<p><a class='btn' href='/grain/new'>+ &#x65b0;&#x898f;&#x767b;&#x9332;</a></p>\n"
             . "<table class='data'><thead><tr>"
             . '<th>Rice-ID</th><th>&#x54c1;&#x7a2e;</th><th>&#x751f;&#x7523;&#x8005;</th>'
             . '<th>&#x5834;&#x6240;</th><th>&#x7530;&#x690d;&#x65e5;</th>'
             . '<th>&#x9032;&#x6357; (88&#x6b65;)</th><th></th>'
             . "</tr></thead><tbody>$rows</tbody></table>\n";
    return $c->html(layout('&#x4e00;&#x89a7;', $body));
});

# GET /grain/new -- the registration form.
$app->get('/grain/new', sub {
    my $c = shift;
    my $body = <<"HTML";
<h2>&#x65b0;&#x898f;&#x767b;&#x9332;</h2>
<form method="post" action="/grain/create">
<div class="form-row">
  <label>&#x54c1;&#x7a2e;&#x540d; <span style="color:red">*</span></label>
  <input type="text" name="variety" placeholder="&#x3053;&#x3057;&#x3072;&#x304b;&#x308a;" required>
</div>
<div class="form-row">
  <label>&#x751f;&#x7523;&#x8005;</label>
  <input type="text" name="grower" placeholder="&#x5c71;&#x7530;&#x592a;&#x90ce;">
</div>
<div class="form-row">
  <label>&#x5834;&#x6240;</label>
  <input type="text" name="location" placeholder="&#x57fc;&#x7389;&#x770c;&#x5927;&#x5bae;&#x5e02;">
</div>
<div class="form-row">
  <label>&#x7530;&#x690d;&#x65e5;</label>
  <input type="text" name="planted_on" placeholder="2026-05-01 / -12000-04-15">
  <div class="date-hint">
    &#x5f62;&#x5f0f;: YYYY-MM-DD &#x307e;&#x305f;&#x306f; -YYYYY-MM-DD&#x3000;
    &#x5e74;: -12000 &#x301c; 1000000&#x3000;&#x6708;&#x65e5;&#x306f;&#x7701;&#x7565;&#x53ef;
  </div>
</div>
<div class="form-row">
  <label>&#x5099;&#x8003;</label>
  <textarea name="note" rows="3"></textarea>
</div>
<p style="margin-top:16px">
  <button class="btn" type="submit">&#x767b;&#x9332;&#x3059;&#x308b;</button>
  <a href="/" style="margin-left:12px">&#x30ad;&#x30e3;&#x30f3;&#x30bb;&#x30eb;</a>
</p>
</form>
HTML
    return $c->html(layout('&#x65b0;&#x898f;&#x767b;&#x9332;', $body));
});

# POST /grain/create -- issue a Rice-ID, insert the grain + 88 status rows.
$app->post('/grain/create', sub {
    my $c       = shift;
    my $id      = RiceID->new->generate;
    my $planted = validate_date($c->param('planted_on'));

    $c->db->insert({
        rice_id    => $id,
        variety    => (defined $c->param('variety')  ? $c->param('variety')  : ''),
        grower     => (defined $c->param('grower')   ? $c->param('grower')   : ''),
        location   => (defined $c->param('location') ? $c->param('location') : ''),
        planted_on => $planted,
        note       => (defined $c->param('note')     ? $c->param('note')     : ''),
        created_at => now(),
    });
    return $c->redirect("/grain/$id");
});

# GET /grain/:id -- detail view and the 88-step status form.
$app->get('/grain/:id', sub {
    my $c  = shift;
    my $id = $c->param('id');

    my $grain = $c->db->get($id);
    return $c->html(layout('404',
        '<h2>404 Not Found</h2><p>' . h($id) . '</p>'), 404)
        unless defined $grain;

    my @steps = @{ $c->db->status_rows($id) };

    my $done = 0;
    my $sd;
    for $sd (@steps) {
        $done++ if defined $sd->{status} && $sd->{status} == 2;
    }
    my $pct = int($done / 88 * 100);

    my %info;
    my $p;
    for $p (@{ RiceProcess->new->all }) { $info{ $p->{key} } = $p }

    my $rows    = '';
    my $cur_cat = '';
    for $sd (@steps) {
        my $i   = $info{ $sd->{step_key} } || {};
        my $cat = defined $i->{category} ? $i->{category} : '';
        if ($cat ne $cur_cat) {
            $rows .= "<div class='section-head'>$cat</div>\n";   # entities: raw
            $cur_cat = $cat;
        }
        my $v   = defined $sd->{status} ? int($sd->{status}) : 0;
        my $nm  = defined $i->{name} ? $i->{name} : $sd->{step_key};  # entities: raw
        $rows .= "<div class='step-row'>"
               . "<div class='step-no'>$sd->{step_no}</div>"
               . "<div class='step-name'>$nm</div>"
               . "<div class='step-sel'><select name='s_$sd->{step_no}'>"
               . "<option value='0'" . ($v == 0 ? ' selected' : '') . ">&#x672a;&#x5b9f;&#x65bd;</option>"
               . "<option value='1'" . ($v == 1 ? ' selected' : '') . ">&#x4f5c;&#x696d;&#x4e2d;</option>"
               . "<option value='2'" . ($v == 2 ? ' selected' : '') . ">&#x5b8c;&#x4e86;</option>"
               . "</select></div></div>\n";
    }

    my $body = "<h2>&#x8a73;&#x7d30;</h2>\n<p>"
             . "<a href='/'>&#x4e00;&#x89a7;&#x306b;&#x623b;&#x308b;</a> | "
             . "<a class='btn btn-sm btn-del' href='/grain/$id/delete'"
             . " onclick=\"return confirm('&#x524a;&#x9664;&#x3057;&#x307e;&#x3059;&#x304b;?')\">"
             . "&#x524a;&#x9664;</a></p>\n"
             . "<table class='data'>\n"
             . '<tr><th>Rice-ID</th><td><code>' . h($id) . '</code></td></tr>'
             . '<tr><th>&#x54c1;&#x7a2e;</th><td>' . h($grain->{variety}) . '</td></tr>'
             . '<tr><th>&#x751f;&#x7523;&#x8005;</th><td>' . h($grain->{grower}) . '</td></tr>'
             . '<tr><th>&#x5834;&#x6240;</th><td>' . h($grain->{location}) . '</td></tr>'
             . '<tr><th>&#x7530;&#x690d;&#x65e5;</th><td>' . format_planted_on($grain->{planted_on}) . '</td></tr>'
             . '<tr><th>&#x5099;&#x8003;</th><td>' . h($grain->{note}) . '</td></tr>'
             . '<tr><th>&#x767b;&#x9332;&#x65e5;&#x6642;</th><td>' . h($grain->{created_at}) . '</td></tr>'
             . '<tr><th>&#x9032;&#x6357;</th><td>'
             . "<span class='bar-wrap'><span class='bar' style='width:${pct}%'></span></span>"
             . " ${done}/88 (${pct}%)</td></tr></table>\n"
             . "<h2>&#x516b;&#x5341;&#x516b;&#x306e;&#x624b;&#x9593;</h2>\n"
             . "<form method='post' action='/grain/$id/update'>\n"
             . $rows
             . "<p style='margin-top:12px'>"
             . "<button class='btn' type='submit'>&#x72b6;&#x614b;&#x3092;&#x66f4;&#x65b0;</button>"
             . "</p></form>\n";
    return $c->html(layout('&#x8a73;&#x7d30;', $body));
});

# POST /grain/:id/update -- persist the 88-step status selectors.
$app->post('/grain/:id/update', sub {
    my $c   = shift;
    my $id  = $c->param('id');
    my $step;
    for $step (@{ RiceProcess->new->all }) {
        my $v = $c->param('s_' . $step->{number});
        $v = 0 unless defined $v && $v =~ /^[012]$/;
        $c->db->update_status($id, $step->{number}, int($v));
    }
    return $c->redirect("/grain/$id");
});

# GET /grain/:id/delete -- remove the grain and its status rows.
$app->get('/grain/:id/delete', sub {
    my $c  = shift;
    my $id = $c->param('id');
    $c->db->remove($id);
    return $c->redirect('/');
});

print "Yaso-Hachi on PSGI::Handy (in-memory)  http://127.0.0.1:8080/\n";
my $psgi = $app->to_app;
HTTP::Handy->run(app => $psgi, host => '127.0.0.1', port => 8080);
