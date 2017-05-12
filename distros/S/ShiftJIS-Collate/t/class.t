use strict;
use vars qw($loaded);
$^W = 1;

BEGIN { $| = 1; print "1..24\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::Collate;

$loaded = 1;
print "ok 1\n";

my $Collator = new ShiftJIS::Collate;
print $Collator ? "ok" : "not ok", " 2\n";

sub sorted {
   my @ary = @_;
   my $cmp = '';
   my $str;
   for $str (@ary) {
      return 0 if ! $Collator->gt($str, $cmp);
      $cmp = $str;
   }
   return 1;
}

my @trail_byte  = map chr, 0x40..0x7E, 0x80..0xFC;
sub extend_trail { my $a = shift; map($a.$_, @trail_byte) }

my @kanji0    = (map "\x81".chr, 0x56..0x5a);

my @kanji1_1  = (map "\x88".chr, 0x9f..0xfc);
my @kanji1_2  = (map extend_trail(chr), 0x89..0x97);
my @kanji1_3  = (map "\x98".chr, 0x40..0x72);
my @kanji1    = (@kanji1_1, @kanji1_2, @kanji1_3);

my @kanji2_1  = (map "\x98".chr, 0x9f..0xfc);
my @kanji2_2  = (map extend_trail(chr), 0x99..0x9F, 0xe0..0xe9);
my @kanji2_3  = (map "\xea".chr, 0x40..0x7e, 0x80..0xa4);
my @kanji2    = (@kanji2_1, @kanji2_2, @kanji2_3);

print @kanji0 ==    5 ? "ok" : "not ok", "  3\n";
print sorted(@kanji0) ? "ok" : "not ok", "  4\n";
print @kanji1 == 2965 ? "ok" : "not ok", "  5\n";
print sorted(@kanji1) ? "ok" : "not ok", "  6\n";
print @kanji2 == 3390 ? "ok" : "not ok", "  7\n";
print sorted(@kanji2) ? "ok" : "not ok", "  8\n";

my @kanji = (@kanji0, @kanji1, @kanji2);
print @kanji == 6360  ? "ok" : "not ok", "  9\n";
print sorted(@kanji)  ? "ok" : "not ok", " 10\n";

my @greek_up  = (map "\x83".chr, 0x9f..0xb6);
my @greek_lo  = (map "\x83".chr, 0xbf..0xd6);
my @cyril_up  = (map "\x84".chr, 0x40..0x60);
my @cyril_lo  = (map "\x84".chr, 0x70..0x7E, 0x80..0x91);
my @europ     = (@greek_lo, @greek_up, @cyril_lo, @cyril_up);

print @europ == 114   ? "ok" : "not ok", " 11\n";
print sorted(@europ)  ? "ok" : "not ok", " 12\n";
my @eurok0 = (@europ, @kanji0);
print @eurok0 == 119  ? "ok" : "not ok", " 13\n";
print sorted(@eurok0) ? "ok" : "not ok", " 14\n";

my @puncts    = (map "\x81".chr, 0x41..0x49, 0x4c..0x51, 0x5c..0x64);
my @parens    = (map "\x81".chr, 0x65..0x7a);
my @digits    = (map "\x82".chr, 0x4f..0x58);
my @symbol    = (@puncts, @parens, @digits);
my @syeuk0    = (@symbol, @eurok0);

print @puncts ==  24  ? "ok" : "not ok", " 15\n";
print sorted(@puncts) ? "ok" : "not ok", " 16\n";
print @parens ==  22  ? "ok" : "not ok", " 17\n";
print sorted(@parens) ? "ok" : "not ok", " 18\n";
print @digits ==  10  ? "ok" : "not ok", " 19\n";
print sorted(@digits) ? "ok" : "not ok", " 20\n";
print @symbol ==  56  ? "ok" : "not ok", " 21\n";
print sorted(@symbol) ? "ok" : "not ok", " 22\n";
print @syeuk0 == 175  ? "ok" : "not ok", " 23\n";
print sorted(@syeuk0) ? "ok" : "not ok", " 24\n";

