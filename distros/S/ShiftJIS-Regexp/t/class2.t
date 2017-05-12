
use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..70\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::Regexp qw(re);

$loaded = 1;
print "ok 1\n";

my @single_byte = map chr, 0..0x7F, 0xA1..0xDF;
my @lead_byte   = map chr, 0x81..0x9F, 0xE0..0xFC;
my @trail_byte  = map chr, 0x40..0x7E, 0x80..0xFC;
sub extend_trail { my $a = shift; map($a.$_, @trail_byte) }
my @double_byte = map extend_trail($_), @lead_byte;
my @sjis_char   = (@single_byte, @double_byte);

print @single_byte ==   191 ? "ok " : "not ok ", " ", ++$loaded, "\n";
print @lead_byte   ==    60 ? "ok " : "not ok ", " ", ++$loaded, "\n";
print @trail_byte  ==   188 ? "ok " : "not ok ", " ", ++$loaded, "\n";
print @double_byte == 11280 ? "ok " : "not ok ", " ", ++$loaded, "\n";
print @sjis_char   == 11471 ? "ok " : "not ok ", " ", ++$loaded, "\n";

my $all_sjis = 11471;

sub test ($$) {
    my($pat, $result) = @_;
    my $re  = re(qq/^$pat/);
    my $grep = grep(/$re/, @sjis_char);
    print $grep == $result ? "ok" : "not ok", " ", ++$loaded, "\n";
}

# 7-8
test('\j', 11471);
test('\J', 11470);

# 9-17
test('\p{kanji1}',   2965);
test('\p{kanji2}',   3390);
test('\p{ascii}',     128);
test('\p{zenkaku}', 11280);
test('\p{x0208}',    6879);
test('\p{jis}',      7070);
test('\p{nec}',       457);
test('\p{ibm}',       388);
test('\p{mswin}',    7915);

# 18-26
test('\P{kanji1}',  $all_sjis -  2965);
test('\P{kanji2}',  $all_sjis -  3390);
test('\P{ascii}',   $all_sjis -   128);
test('\P{zenkaku}', $all_sjis - 11280);
test('\P{x0208}',   $all_sjis -  6879);
test('\P{jis}',     $all_sjis -  7070);
test('\P{nec}',     $all_sjis -   457);
test('\P{ibm}',     $all_sjis -   388);
test('\P{mswin}',   $all_sjis -  7915);

# 27-30
test('\p{halfwidth}',91);
test('\p{fullwidth}',91);
test('[!#$%&()*+,./0-9:;<=>?@A-Z\[\x5c\]^_`a-z{|}~]', 91);
test('[\x{8143}\x{8144}\x{8146}-\x{8149}\x{814D}\x{814F}-\x{8151}'.
      '\x{815E}\x{8162}\x{8169}\x{816A}\x{816D}-\x{8170}\x{817B}'.
      '\x{8181}\x{8183}\x{8184}\x{818F}\x{8190}\x{8193}-\x{8197}'.
      '\x{824F}-\x{8258}\p{FullLatin}]', 91);

# 31-37
test('[\x{8740}-\x{875D}\x{875F}-\x{8775}\x{877E}-\x{879C}]', 83); # NEC
test('[\x{ED40}-\x{EEEC}\x{EEEF}-\x{EEFC}]', 374); # NEC/IBM
test('[\x{FA40}-\x{FC4B}]', 388); # IBM
test('[\0-\x{fcfc}]',       11471); # all shift-jis
test('[\0-\x{effc}]',        9027); # narrow shift-jis
test('[\x{8140}-\x{effc}]',  8836); #  94x94
test('[\x{8140}-\x{fcfc}]', 11280); # 120x94

# 38-44
test('[\x{889F}-\x{9872}]', 2965); # level 1
test('[\x{989F}-\x{EAA4}]', 3390); # level 2
test('[\x{879F}-\x{889E}\x{9873}-\x{989E}\x{EAA5}-\x{EFFC}]', 1259); # level 3
test('[\x{F040}-\x{FCF4}]', 2436); # level 4
test('[\x{889F}-\x{9872}\x{989F}-\x{EAA4}]', 6355); # level 1+2
test('[\x{879F}-\x{EFFC}]',  7614); # level 1-3
test('[\x{879F}-\x{FCF4}]', 10050); # level 1-4

# 45-47
test('[\x{ED40}-\x{EEEC}]',  360); # NEC kanji
test('[\x{FA5C}-\x{FC4B}]',  360); # IBM kanji
test('[\x{ED40}-\x{EEEC}\x{FA5C}-\x{FC4B}]',  720); # vendor kanji

# 48-52
# JIS X 0213:2004 Assigned code points
test('[\x{8140}-\x{82F9}\x{8340}-\x{84DC}\x{84E5}-\x{84FA}'.
      '\x{8540}-\x{86F1}\x{86FB}-\x{8776}\x{877E}-\x{878F}'.
      '\x{8793}\x{8798}\x{8799}\x{879D}-\x{FCF4}]', 11233);

# JIS X 0213:2004 (plane 1) Assigned code points
test('[\x{8140}-\x{82F9}\x{8340}-\x{84DC}\x{84E5}-\x{84FA}'.
      '\x{8540}-\x{86F1}\x{86FB}-\x{8776}\x{877E}-\x{878F}'.
      '\x{8793}\x{8798}\x{8799}\x{879D}-\x{EFFC}]', 8797);

# JIS X 0213:2004 Unassigned code points
test('[\x{82FA}-\x{82FC}\x{84DD}-\x{84E4}\x{84FB}\x{84FC}'.
      '\x{86F2}-\x{86FA}\x{8777}-\x{877D}\x{8790}-\x{8792}'.
      '\x{8794}-\x{8797}\x{879A}-\x{879C}\x{FCF5}-\x{FCFC}]', 47);

# JIS X 0213:2004 (plane 1) Unassigned code points
test('[\x{82FA}-\x{82FC}\x{84DD}-\x{84E4}\x{84FB}\x{84FC}'.
      '\x{86F2}-\x{86FA}\x{8777}-\x{877D}\x{8790}-\x{8792}'.
      '\x{8794}-\x{8797}\x{879A}-\x{879C}]', 39);

# addition in 2004
test('[\x{879F}\x{889E}\x{9873}\x{989E}\x{EAA5}\x{EFF8}-\x{EFFC}]', 10);

# 53-54
test('[\x{F040}-\x{F9FC}]', 1880);  # windoes EUDC
test('[\x{F040}-\x{FCFC}]', 2444);  # Mac UDC

# 55-60
test('[\x{8740}-\x{8753}\x{84BF}-\x{84DC}]', 50); # circled 1-50 by X0213
test('[\x{8740}-\x{8753}]', 20); # circled 1-20 in NEC
test('[\x{8540}-\x{8553}]', 20); # circled 1-20 in MacOS
test('[\x{83D8}-\x{83E1}]', 10); # double circled 1-10 by X0213
test('[\x{869F}-\x{86B2}]', 20); # negative circled 1-20 by X0213
test('[\x{857C}-\x{8585}]',  9); # negative circled 1-9 in MacOS

# 61-68
test('[\x{86B3}-\x{86BE}]', 12);         # JIS X 0213 i-xii
test('[\x{8754}-\x{875E}\x{8776}]', 12); # JIS X 0213 I-XII
test('[\x{8754}-\x{875D}]', 10);         # NEC I-X
test('[\x{EEEF}-\x{EEF8}]', 10);         # NEC/IBM i-x
test('[\x{FA40}-\x{FA49}]', 10);         # IBM i-x
test('[\x{FA4A}-\x{FA53}]', 10);         # IBM I-X
test('[\x{859F}-\x{85AD}]', 15);         # MacOS I-XV
test('[\x{85B3}-\x{85C1}]', 15);         # MacOS i-xv

# 69-70

# 2-byte chars in JIS X 0213 corresponding to ASCII graphic chars
test('[\x{8149}\x{81AE}\x{8194}\x{8190}\x{8193}\x{8195}\x{81AD}'.
      '\x{8169}\x{816A}\x{8196}\x{817B}\x{8143}\x{81AF}\x{8144}'.
      '\x{815E}\x{824F}-\x{8258}\x{8146}\x{8147}\x{8183}\x{8181}'.
      '\x{8184}\x{8148}\x{8197}\x{8260}-\x{8279}\x{816D}\x{815F}'.
      '\x{816E}\x{814F}\x{8151}\x{814D}\x{8281}-\x{829A}\x{816F}'.
      '\x{8162}\x{8170}\x{81B0}]', 94);

# 2-byte chars in Windows CP-932 corresponding to ASCII graphic chars
test('[\x{8149}\x{FA57}\x{8194}\x{8190}\x{8193}\x{8195}\x{FA56}'.
      '\x{8169}\x{816A}\x{8196}\x{817B}\x{8143}\x{817C}\x{8144}'.
      '\x{815E}\x{824F}-\x{8258}\x{8146}\x{8147}\x{8183}\x{8181}'.
      '\x{8184}\x{8148}\x{8197}\x{8260}-\x{8279}\x{816D}\x{815F}'.
      '\x{816E}\x{814F}\x{8151}\x{814D}\x{8281}-\x{829A}\x{816F}'.
      '\x{8162}\x{8170}\x{8160}]', 94);


