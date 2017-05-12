
use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..500\n"; }
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

sub test_ok ($$) {
    my($pat, $result) = @_;
    my $re  = re(qq/^$pat/);
    my $grep = join('', grep /$re/, @sjis_char);
    print $grep eq $result ? "ok" : "not ok", " ", ++$loaded, "\n";
}

sub test_no ($$) {
    my($pat, $result) = @_;
    my $re  = re(qq/^$pat/);
    my $grep = join('', grep !/$re/, @sjis_char);
    print $grep eq $result ? "ok" : "not ok", " ", ++$loaded, "\n";
}

my $all_sjis  = join('', @sjis_char);
my $xdigit    = pack('C*', 0x30..0x39, 0x41..0x46, 0x61..0x66);
my $hw_digit  = pack('C*', 0x30..0x39);
my $fw_digit  = pack('n*', 0x824f..0x8258);
my $digit     = $hw_digit.$fw_digit;
my $hw_lower  = pack('C*', 0x61..0x7a);
my $fw_lower  = pack('n*', 0x8281..0x829a);
my $lower     = $hw_lower.$fw_lower;
my $hw_upper  = pack('C*', 0x41..0x5a);
my $fw_upper  = pack('n*', 0x8260..0x8279);
my $upper     = $hw_upper.$fw_upper;
my $hw_alpha  = $hw_upper.$hw_lower;
my $fw_alpha  = $fw_upper.$fw_lower;
my $alpha     = $hw_alpha.$fw_alpha;
my $hw_alnum  = $hw_digit.$hw_alpha;
my $fw_alnum  = $fw_digit.$fw_alpha;
my $alnum     = $hw_alnum.$fw_alnum;

my $s_char    = "\x09\x0A\x0C\x0D\x20";
my $hw_space  = "\x09\x0A\x0B\x0C\x0D\x20";
my $fw_space  = "\x81\x40";
my $space     = $hw_space.$fw_space;
my $blank     = "\x09\x20\x81\x40";
my $ascii     = pack('C*', 0x00..0x7F);
my $cntrl     = pack('C*', 0x00..0x1F, 0x7F);
my $roman     = pack('C*', 0x21..0x7E);

my $hankaku   = pack('C*', 0xA1..0xDF);
my $zenkaku   = join('', @double_byte);
my $halfwidth = pack('C*', 0x21, 0x23..0x26, 0x28..0x2c, 0x2e..0x7e);
my $fullwidth = pack('n*', 0x8143, 0x8144, 0x8146..0x8149, 0x814d,
   0x814f..0x8151, 0x815e, 0x8162, 0x8169..0x816a, 0x816d..0x8170, 0x817b,
   0x8181, 0x8183, 0x8184, 0x818f, 0x8190, 0x8193..0x8197). $fw_alnum;

my $latin     = $hw_alpha;
my $fulllatin = $fw_alpha;
my $greek     = pack('n*', 0x839f..0x83b6, 0x83bf..0x83d6);
my $cyrillic  = pack('n*', 0x8440..0x8460, 0x8470..0x847E, 0x8480..0x8491);
my $european  = $alpha.$greek.$cyrillic;

my $halfkana  = pack('C*', 0xa6..0xdf);
my $fw_hira   = pack('n*', 0x829f..0x82f1);
my $hiragana  = pack('n*', 0x814a, 0x814b, 0x8154, 0x8155).$fw_hira;
my $fw_kata   = pack('n*', 0x8340..0x837E, 0x8380..0x8396);
my $katakana  = pack('n*', 0x8152, 0x8153, 0x815b).$fw_kata;
my $like_kana = pack('n*', 0x814a, 0x814b, 0x8152..0x8155, 0x815b);
my $fullkana  = $like_kana.$fw_hira.$fw_kata;
my $kana      = $halfkana.$fullkana;

my $kanji0    = pack('n*', 0x8156..0x815a);
my $kanji1_1  = pack('n*', 0x889f..0x88fc);
my $kanji1_2  = join('', map extend_trail(chr), 0x89..0x97);
my $kanji1_3  = pack('n*', 0x9840..0x9872);
my $kanji1    = $kanji1_1.$kanji1_2.$kanji1_3;
my $kanji2_1  = pack('n*', 0x989f..0x98fc);
my $kanji2_2  = join('', map extend_trail(chr), 0x99..0x9F, 0xe0..0xe9);
my $kanji2_3  = pack('n*', 0xea40..0xea7e, 0xea80..0xeaa4);
my $kanji2    = $kanji2_1.$kanji2_2.$kanji2_3;
my $kanji     = $kanji0.$kanji1.$kanji2;
my $boxdrawing = pack('n*', 0x849f..0x84be);

my $w_char    = $hw_digit.$hw_upper. '_' . $hw_lower;
my $hw_word   = $w_char . $halfkana;
my $like_word = pack('n*', 0x814a, 0x814b, 0x8152..0x815b);
my $fw_hkgc   = $fw_hira.$fw_kata.$greek.$cyrillic;
my $fw_word   = $like_word.$fw_alnum.$fw_hkgc.$kanji1.$kanji2;
my $word      = $hw_word.$fw_word;

my $hw_punct  = pack('C*', 0x21..0x2f, 0x3a..0x40, 0x5b..0x60, 0x7b..0x7e,
                           0xa1..0xa5);
my $fw_punct  = pack('n*', 0x8141..0x8149, 0x814c..0x8151, 0x815c..0x817e,
           0x8180..0x81ac, 0x81b8..0x81bf, 0x81c8..0x81ce, 0x81da..0x81e8,
           0x81f0..0x81f7, 0x81fc);
my $punct     = $hw_punct.$fw_punct.$boxdrawing;

my $hw_graph  = $roman.$hankaku;
my $fw_gr81   = pack('n*', 0x8141..0x817e, 0x8180..0x81ac, 0x81b8..0x81bf,
           0x81c8..0x81ce, 0x81da..0x81e8, 0x81f0..0x81f7, 0x81fc);
my $fw_graph  = $fw_gr81.$fw_alnum.$fw_hkgc.$boxdrawing.$kanji1.$kanji2;
my $graph     = $hw_graph.$fw_graph;

my $hw_print  = "\x20".$hw_graph;
my $fw_print  = $fw_space.$fw_graph;
my $print     = $hw_print.$fw_print;

my $x0201     = pack('C*', 0x20..0x7f, 0xa1..0xdf);
my $x0208     = $fw_print;
my $x0211     = pack('C*', 0x00..0x1f);
my $hw_jis    = $x0211.$x0201;
my $jis       = $hw_jis.$x0208;

my $nec_1     = pack('n*', 0x8740..0x875d, 0x875f..0x8775, 0x877e,
                           0x8780..0x879c);
my $nec_2     = pack('n*', 0xed40..0xed7e, 0xed80..0xedfc);
my $nec_3     = pack('n*', 0xee40..0xee7e, 0xee80..0xeeec, 0xeeef..0xeefc);
my $nec       = $nec_1.$nec_2.$nec_3;
my $ibm_1     = join('', map extend_trail(chr), 0xfa, 0xfb);
my $ibm_2     = pack('n*', 0xfc40..0xfc4b);
my $ibm       = $ibm_1.$ibm_2;
my $vendor    = $nec.$ibm;
my $mswin     = $hw_jis.$fw_space.$fw_gr81.$fw_alnum.$fw_hkgc.$boxdrawing.
                $nec_1.$kanji1.$kanji2.$nec_2.$nec_3.$ibm;

# 7-12
test_ok('\j', $all_sjis);
test_no('\j', '');
test_ok('[\0-\x{fcfc}]', $all_sjis);
test_no('[\0-\x{fcfc}]', '');
test_no('.',  "\n");
test_no('\J', "\n");

# 13-20
test_ok('[\n]',  "\n");
test_no('[^\n]', "\n");
test_ok('[\r]',  "\r");
test_no('[^\r]', "\r");
test_ok('[\t]',  "\t");
test_no('[^\t]', "\t");
test_ok('[\f]',  "\f");
test_no('[^\f]', "\f");

# 21-28
test_ok('[\a]',  "\a");
test_no('[^\a]', "\a");
test_ok('[\b]',  "\b");
test_no('[^\b]', "\b");
test_ok('[\e]',  "\e");
test_no('[^\e]', "\e");
test_ok('[\0]',  "\0");
test_no('[^\0]', "\0");

# 29-36
test_ok('\d',    $hw_digit);
test_ok('[\d]',  $hw_digit);
test_ok('[^\D]', $hw_digit);
test_ok('[0-9]', $hw_digit);
test_no('\D',    $hw_digit);
test_no('[\D]',  $hw_digit);
test_no('[^\d]', $hw_digit);
test_no('[^0-9]',$hw_digit);

# 37-42
test_ok('\w',    $w_char);
test_ok('[\w]',  $w_char);
test_ok('[^\W]', $w_char);
test_no('\W',    $w_char);
test_no('[\W]',  $w_char);
test_no('[^\w]', $w_char);

# 43-50
test_ok('\s',    $s_char);
test_ok('[\s]',  $s_char);
test_ok('[^\S]', $s_char);
test_ok('[\t\n\r\f ]', $s_char);
test_no('\S',    $s_char);
test_no('[\S]',  $s_char);
test_no('[^\s]', $s_char);
test_no('[^\t\n\r\f ]', $s_char);

# 51-70
test_ok('\pX',    $xdigit);
test_ok('\P^X',   $xdigit);
test_ok('[\pX]',  $xdigit);
test_ok('[\P^X]', $xdigit);
test_ok('[^\PX]', $xdigit);
test_ok('\p{Xdigit}',     $xdigit);
test_ok('\P{^Xdigit}',    $xdigit);
test_ok('[[:xdigit:]]',   $xdigit);
test_ok('[^[:^xdigit:]]', $xdigit);
test_ok('[0-9A-Fa-f]',    $xdigit);
test_no('\PX',    $xdigit);
test_no('\p^X',   $xdigit);
test_no('[\PX]',  $xdigit);
test_no('[\p^X]', $xdigit);
test_no('[^\pX]', $xdigit);
test_no('\P{Xdigit}',    $xdigit);
test_no('\p{^Xdigit}',   $xdigit);
test_no('[[:^xdigit:]]', $xdigit);
test_no('[^[:xdigit:]]', $xdigit);
test_no('[^0-9A-Fa-f]',  $xdigit);

# 71-80
test_ok('\pD',         $digit);
test_ok('[\pD]',       $digit);
test_ok('\p{Digit}',   $digit);
test_ok('[[:digit:]]', $digit);
test_ok('[0-9ÇO-ÇX]',  $digit);
test_no('\PD',         $digit);
test_no('[\PD]',       $digit);
test_no('\P{Digit}',   $digit);
test_no('[[:^digit:]]',$digit);
test_no('[^0-9ÇO-ÇX]', $digit);

# 81-90
test_ok('\pU',         $upper);
test_ok('[\pU]',       $upper);
test_ok('\p{Upper}',   $upper);
test_ok('[[:upper:]]', $upper);
test_ok('[A-ZÇ`-Çy]',  $upper);
test_no('\PU',         $upper);
test_no('[\PU]',       $upper);
test_no('\P{Upper}',   $upper);
test_no('[[:^upper:]]',$upper);
test_no('[^A-ZÇ`-Çy]', $upper);

# 91-100
test_ok('\pL',         $lower);
test_ok('[\pL]',       $lower);
test_ok('\p{Lower}',   $lower);
test_ok('[[:lower:]]', $lower);
test_ok('[a-zÇÅ-Çö]',  $lower);
test_no('\PL',         $lower);
test_no('[\PL]',       $lower);
test_no('\P{Lower}',   $lower);
test_no('[[:^lower:]]',$lower);
test_no('[^a-zÇÅ-Çö]', $lower);

# 101-104
test_ok('(?i)[A-ZÇ`-Çy]',  $hw_alpha.$fw_upper);
test_no('(?i)[^A-ZÇ`-Çy]', $hw_alpha.$fw_upper);
test_ok('(?i)[a-zÇÅ-Çö]',  $hw_alpha.$fw_lower);
test_no('(?i)[^a-zÇÅ-Çö]', $hw_alpha.$fw_lower);

# 104-112
test_ok('\pA',         $alpha);
test_ok('[\pA]',       $alpha);
test_ok('\p{Alpha}',   $alpha);
test_ok('[[:alpha:]]', $alpha);
test_no('\PA',         $alpha);
test_no('[\PA]',       $alpha);
test_no('\P{Alpha}',   $alpha);
test_no('[[:^alpha:]]',$alpha);

# 113-120
test_ok('\pQ',         $alnum);
test_ok('[\pQ]',       $alnum);
test_ok('\p{Alnum}',   $alnum);
test_ok('[[:alnum:]]', $alnum);
test_no('\PQ',         $alnum);
test_no('[\PQ]',       $alnum);
test_no('\P{Alnum}',   $alnum);
test_no('[[:^alnum:]]',$alnum);

# 121-130
test_ok('[\pU\pL]',              $alpha);
test_ok('[\p{Upper}\p{Lower}]',  $alpha);
test_no('[^\pU\pL]',             $alpha);
test_no('[^\p{Upper}\p{Lower}]', $alpha);
test_ok('[\pA\pD]',              $alnum);
test_no('[^\pA\pD]',             $alnum);
test_ok('[\p{Alpha}\pD]',        $alnum);
test_no('[^\p{Alpha}\pD]',       $alnum);
test_ok('[\p{Alpha}\p{Digit}]',  $alnum);
test_no('[^\p{Alpha}\p{Digit}]', $alnum);

# 131-138
test_ok('\pW',        $word);
test_ok('[\pW]',      $word);
test_ok('\p{Word}',   $word);
test_ok('[[:word:]]', $word);
test_no('\PW',        $word);
test_no('[\PW]',      $word);
test_no('\P{Word}',   $word);
test_no('[[:^word:]]',$word);

# 139-146
test_ok('\pP',         $punct);
test_ok('[\pP]',       $punct);
test_ok('\p{Punct}',   $punct);
test_ok('[[:punct:]]', $punct);
test_no('\PP',         $punct);
test_no('[\PP]',       $punct);
test_no('\P{Punct}',   $punct);
test_no('[[:^punct:]]',$punct);

# 147-154
test_ok('\pG',         $graph);
test_ok('[\pG]',       $graph);
test_ok('\p{Graph}',   $graph);
test_ok('[[:graph:]]', $graph);
test_no('\PG',         $graph);
test_no('[\PG]',       $graph);
test_no('\P{Graph}',   $graph);
test_no('[[:^graph:]]',$graph);

# 155-162
test_ok('\pT',         $print);
test_ok('[\pT]',       $print);
test_ok('\p{Print}',   $print);
test_ok('[[:print:]]', $print);
test_no('\PT',         $print);
test_no('[\PT]',       $print);
test_no('\P{Print}',   $print);
test_no('[[:^print:]]',$print);

# 163-170
test_ok('\pS',         $space);
test_ok('[\pS]',       $space);
test_ok('\p{Space}',   $space);
test_ok('[[:space:]]', $space);
test_no('\PS',         $space);
test_no('[\PS]',       $space);
test_no('\P{Space}',   $space);
test_no('[[:^space:]]',$space);

# 171-178
test_ok('\pB',         $blank);
test_ok('[\pB]',       $blank);
test_ok('\p{Blank}',   $blank);
test_ok('[[:blank:]]', $blank);
test_no('\PB',         $blank);
test_no('[\PB]',       $blank);
test_no('\P{Blank}',   $blank);
test_no('[[:^blank:]]',$blank);

# 179-186
test_ok('\pC',         $cntrl);
test_ok('[\pC]',       $cntrl);
test_ok('\p{Cntrl}',   $cntrl);
test_ok('[[:cntrl:]]', $cntrl);
test_no('\PC',         $cntrl);
test_no('[\PC]',       $cntrl);
test_no('\P{cntrl}',   $cntrl);
test_no('[[:^cntrl:]]',$cntrl);

# 187-194
test_ok('\p{ASCII}',    $ascii);
test_ok('[[:ascii:]]',  $ascii);
test_ok('[\0-\c?]',     $ascii);
test_ok('[\0-\x7F]',    $ascii);
test_no('\P{ASCII}',    $ascii);
test_no('[[:^ascii:]]', $ascii);
test_no('[^\0-\c?]',    $ascii);
test_no('[^\0-\x7F]',   $ascii);

# 195-202
test_ok('[\p{Blank}\x09-\x0D]',  $space);
test_ok('[\x09-\x0D\pB]',        $space);
test_no('[^\p{Blank}\x09-\x0D]', $space);
test_no('[^\x09-\x0D\pB]',       $space);
test_ok('[\s\x{8140}]',          $s_char.$fw_space);
test_no('[^\s\x{8140}]',         $s_char.$fw_space);
test_ok('[\s\x0B\x{8140}]',      $space);
test_no('[^\s\x0B\x{8140}]',     $space);

# 203-206
test_ok('[\pW\pP]',            $graph);
test_ok('[\p{Word}\p{Punct}]', $graph);
test_no('[^\pW\pP]',           $graph);
test_no('[^\p{Word}\p{Punct}]',$graph);

# 207-210
test_ok('[\pB\pG]',             "\t".$print);
test_ok('[\p{Blank}\p{Graph}]', "\t".$print);
test_no('[^\pB\pG]',            "\t".$print);
test_no('[^\p{Blank}\p{Graph}]',"\t".$print);

# 211-220
test_ok('\pR',         $roman);
test_ok('[\pR]',       $roman);
test_ok('\p{Roman}',   $roman);
test_ok('[[:roman:]]', $roman);
test_ok('[\x21-\x7E]', $roman);
test_no('\PR',         $roman);
test_no('[\PR]',       $roman);
test_no('\P{Roman}',   $roman);
test_no('[[:^roman:]]',$roman);
test_no('[^\x21-\x7E]',$roman);

# 221-230
test_ok('\pY',           $hankaku);
test_ok('[\pY]',         $hankaku);
test_ok('\p{Hankaku}',   $hankaku);
test_ok('[[:hankaku:]]', $hankaku);
test_ok('[\xA1-\xDF]',   $hankaku);
test_no('\PY',           $hankaku);
test_no('[\PY]',         $hankaku);
test_no('\P{Hankaku}',   $hankaku);
test_no('[[:^hankaku:]]',$hankaku);
test_no('[^\xA1-\xDF]',  $hankaku);

# 231-240
test_ok('\pZ',           $zenkaku);
test_ok('[\pZ]',         $zenkaku);
test_ok('\p{Zenkaku}',   $zenkaku);
test_ok('[[:zenkaku:]]', $zenkaku);
test_ok('[^\0-\xDF}]',   $zenkaku);
test_no('\PZ',           $zenkaku);
test_no('[\PZ]',         $zenkaku);
test_no('\P{Zenkaku}',   $zenkaku);
test_no('[[:^zenkaku:]]',$zenkaku);
test_no('[\0-\xDF}]',    $zenkaku);

# 241-246
test_ok('\p{Halfwidth}',   $halfwidth);
test_ok('[\p{Halfwidth}]', $halfwidth);
test_ok('[[:halfwidth:]]', $halfwidth);
test_no('\P{Halfwidth}',   $halfwidth);
test_no('[\P{Halfwidth}]', $halfwidth);
test_no('[[:^halfwidth:]]',$halfwidth);

# 247-254
test_ok('\pF',           $fullwidth);
test_ok('[\pF]',         $fullwidth);
test_ok('\p{Fullwidth}', $fullwidth);
test_no('\PF',           $fullwidth);
test_no('[\PF]',         $fullwidth);
test_no('\P{Fullwidth}', $fullwidth);
test_ok('[[:fullwidth:]]',  $fullwidth);
test_no('[[:^fullwidth:]]', $fullwidth);

# 255-260
test_ok('\p{x0201}',   $x0201);
test_ok('[\p{x0201}]', $x0201);
test_ok('[[:x0201:]]', $x0201);
test_no('\P{x0201}',   $x0201);
test_no('[\P{x0201}]', $x0201);
test_no('[[:^x0201:]]',$x0201);

# 261-268
test_ok('\p{x0211}',   $x0211);
test_ok('[\p{x0211}]', $x0211);
test_ok('[[:x0211:]]', $x0211);
test_ok('[\x00-\x1F]', $x0211);
test_no('\P{x0211}',   $x0211);
test_no('[\P{x0211}]', $x0211);
test_no('[[:^x0211:]]',$x0211);
test_no('[^\x00-\x1F]',$x0211);

# 269-274
test_ok('\p{x0208}',   $x0208);
test_ok('[\p{x0208}]', $x0208);
test_ok('[[:x0208:]]', $x0208);
test_no('\P{x0208}',   $x0208);
test_no('[\P{x0208}]', $x0208);
test_no('[[:^x0208:]]',$x0208);

# 275-282
test_ok('[\x{8140}-\x{FCFC}]',   $zenkaku);
test_no('[^\x{8140}-\x{FCFC}]',  $zenkaku);
test_ok('[^\p{X0201}\p{X0211}]', $zenkaku);
test_no('[\p{X0201}\p{X0211}]',  $zenkaku);
test_ok('[^\p{ASCII}\pY]',       $zenkaku);
test_no('[\p{ASCII}\pY]',        $zenkaku);
test_ok('[^\0-\x7F\xA1-\xDF}]',  $zenkaku);
test_no('[\0-\x7F\xA1-\xDF}]',   $zenkaku);

# 283-286
test_ok('[\x20-\x7F\xA1-\xDF]',  $x0201);
test_no('[^\x20-\x7F\xA1-\xDF]', $x0201);
test_ok('[\p{x0201}\p{x0208}]',  $x0201.$x0208);
test_no('[^\p{x0201}\p{x0208}]', $x0201.$x0208);

# 287-294
test_ok('\pJ',       $jis);
test_ok('[\pJ]',     $jis);
test_ok('\p{JIS}',   $jis);
test_ok('[[:jis:]]', $jis);
test_no('\PJ',       $jis);
test_no('[\PJ]',     $jis);
test_no('\P{JIS}',   $jis);
test_no('[[:^jis:]]',$jis);

# 295-300
test_ok('[\pT\pC]',              $jis);
test_ok('[\p{Print}\p{Cntrl}]',  $jis);
test_no('[^\pT\pC]',             $jis);
test_no('[^\p{Print}\p{Cntrl}]', $jis);
test_ok('[\p{X0201}\p{X0208}\p{X0211}]',  $jis);
test_no('[^\p{X0201}\p{X0208}\p{X0211}]', $jis);

# 301-310
test_ok('\pN',       $nec);
test_ok('[\pN]',     $nec);
test_ok('\p{NEC}',   $nec);
test_ok('[[:nec:]]', $nec);
test_no('\PN',       $nec);
test_no('[\PN]',     $nec);
test_no('\P{NEC}',   $nec);
test_no('[[:^nec:]]',$nec);

my $nec_range = '\x{8740}-\x{875D}\x{875F}-\x{8775}\x{877E}-\x{879C}'
               .'\x{ED40}-\x{EEEC}\x{EEEF}-\x{EEFC}';
test_ok("[$nec_range]",  $nec);
test_no("[^$nec_range]", $nec);

# 311-320
test_ok('\pI',       $ibm);
test_ok('[\pI]',     $ibm);
test_ok('\p{IBM}',   $ibm);
test_ok('[[:ibm:]]', $ibm);
test_no('\PI',       $ibm);
test_no('[\PI]',     $ibm);
test_no('\P{IBM}',   $ibm);
test_no('[[:^ibm:]]',$ibm);
test_ok('[\x{fa40}-\x{fc4b}]', $ibm);
test_no('[^\x{fa40}-\x{fc4b}]',$ibm);

# 321-330
test_ok('\pV',          $vendor);
test_ok('[\pV]',        $vendor);
test_ok('\p{Vendor}',   $vendor);
test_ok('[[:vendor:]]', $vendor);
test_ok('[\pN\pI]',     $vendor);
test_no('\PV',          $vendor);
test_no('[\PV]',        $vendor);
test_no('\P{Vendor}',   $vendor);
test_no('[[:^vendor:]]',$vendor);
test_no('[^\pN\pI]',    $vendor);

# 331-340
test_ok('\pM',         $mswin);
test_ok('[\pM]',       $mswin);
test_ok('\p{MSWin}',   $mswin);
test_ok('[[:mswin:]]', $mswin);
test_ok('[\pJ\pV]',    $mswin);
test_no('\PM',         $mswin);
test_no('[\PM]',       $mswin);
test_no('\P{MSWin}',   $mswin);
test_no('[[:^mswin:]]',$mswin);
test_no('[^\pJ\pV]',   $mswin);

# 341-350
test_ok('\p{Latin}',   $latin);
test_ok('[[:latin:]]', $latin);
test_ok('[A-Za-z]',    $latin);
test_ok('(?i)[a-z]',   $latin);
test_ok('(?i)[A-Z]',   $latin);
test_no('\P{Latin}',   $latin);
test_no('[[:^latin:]]',$latin);
test_no('[^A-Za-z]',   $latin);
test_no('(?i)[^a-z]',  $latin);
test_no('(?i)[^A-Z]',  $latin);

# 351-360
test_ok('\p{FullLatin}',   $fulllatin);
test_ok('[[:fulllatin:]]', $fulllatin);
test_ok('[Ç`-ÇyÇÅ-Çö]',    $fulllatin);
test_ok('(?I)[ÇÅ-Çö]',     $fulllatin);
test_ok('(?I)[Ç`-Çy]',     $fulllatin);
test_no('\P{FullLatin}',   $fulllatin);
test_no('[[:^fulllatin:]]',$fulllatin);
test_no('[^Ç`-ÇyÇÅ-Çö]',   $fulllatin);
test_no('(?I)[^ÇÅ-Çö]',    $fulllatin);
test_no('(?I)[^Ç`-Çy]',    $fulllatin);

# 361-370
test_ok('\p{Greek}',    $greek);
test_ok('[[:greek:]]',  $greek);
test_ok('[Éü-É∂Éø-É÷]', $greek);
test_ok('(?I)[Éø-É÷]',  $greek);
test_ok('(?I)[Éü-É∂]',  $greek);
test_no('\P{Greek}',    $greek);
test_no('[[:^greek:]]', $greek);
test_no('[^Éü-É∂Éø-É÷]',$greek);
test_no('(?I)[^Éø-É÷]', $greek);
test_no('(?I)[^Éü-É∂]', $greek);

# 371-380
test_ok('\p{Cyrillic}',   $cyrillic);
test_ok('[[:cyrillic:]]', $cyrillic);
test_ok('[Ñ@-Ñ`Ñp-Ñë]',   $cyrillic);
test_ok('(?I)[Ñp-Ñë]',    $cyrillic);
test_ok('(?I)[Ñ@-Ñ`]',    $cyrillic);
test_no('\P{Cyrillic}',   $cyrillic);
test_no('[[:^cyrillic:]]',$cyrillic);
test_no('[^Ñ@-Ñ`Ñp-Ñë]',  $cyrillic);
test_no('(?I)[^Ñp-Ñë]',   $cyrillic);
test_no('(?I)[^Ñ@-Ñ`]',   $cyrillic);

# 381-384
test_ok('\p{European}',   $european);
test_ok('[[:european:]]', $european);
test_no('\P{European}',   $european);
test_no('[[:^european:]]',$european);

# 385-390
test_ok('[\p{Latin}\p{FullLatin}]',  $alpha);
test_no('[^\p{Latin}\p{FullLatin}]', $alpha);
test_ok('[\p{Alpha}\p{Greek}\p{Cyrillic}]', $european);
test_no('[^\p{Alpha}\p{Greek}\p{Cyrillic}]',$european);
test_ok('[\p{Greek}\p{Cyrillic}]',   $greek.$cyrillic);
test_no('[^\p{Greek}\p{Cyrillic}]',  $greek.$cyrillic);

# 391-400
test_ok('\p{HalfKana}',   $halfkana);
test_ok('[\p{HalfKana}]', $halfkana);
test_ok('[[:halfkana:]]', $halfkana);
test_ok('[¶-ﬂ]',          $halfkana);
test_ok('[\xA6-\xDF]',    $halfkana);
test_no('\P{HalfKana}',   $halfkana);
test_no('[\P{HalfKana}]', $halfkana);
test_no('[[:^halfkana:]]',$halfkana);
test_no('[^¶-ﬂ]',         $halfkana);
test_no('[^\xA6-\xDF]',   $halfkana);

# 401-410
test_ok('\pH',             $hiragana);
test_ok('[\pH]',           $hiragana);
test_ok('\p{Hiragana}',    $hiragana);
test_ok('[[:hiragana:]]',  $hiragana);
test_ok('[Çü-ÇÒÅJÅKÅTÅU]', $hiragana);
test_no('\PH',             $hiragana);
test_no('[\PH]',           $hiragana);
test_no('\P{Hiragana}',    $hiragana);
test_no('[[:^hiragana:]]', $hiragana);
test_no('[^Çü-ÇÒÅJÅKÅTÅU]',$hiragana);

# 411-420
test_ok('\pK',             $katakana);
test_ok('[\pK]',           $katakana);
test_ok('\p{Katakana}',    $katakana);
test_ok('[[:katakana:]]',  $katakana);
test_ok('[É@-ÉñÅ[ÅRÅS]',   $katakana);
test_no('\PK',             $katakana);
test_no('[\PK]',           $katakana);
test_no('\P{Katakana}',    $katakana);
test_no('[[:^katakana:]]', $katakana);
test_no('[^É@-ÉñÅ[ÅRÅS]',  $katakana);

# 421-430
test_ok('[\pH\pK]',       $fullkana);
test_ok('[\pK\pH]',       $fullkana);
test_ok('\p{FullKana}',   $fullkana);
test_ok('[\p{FullKana}]', $fullkana);
test_ok('[[:fullkana:]]', $fullkana);
test_no('[^\pH\pK]',      $fullkana);
test_no('[^\pK\pH]',      $fullkana);
test_no('\P{FullKana}',   $fullkana);
test_no('[\P{FullKana}]', $fullkana);
test_no('[[:^fullkana:]]',$fullkana);

# 431-440
test_ok('\p{Kana}',    $kana);
test_ok('[[:kana:]]',  $kana);
test_no('\P{Kana}',    $kana);
test_no('[[:^kana:]]', $kana);
test_ok('[\xA6-\xDF\pH\pK]',  $kana);
test_no('[^\xA6-\xDF\pH\pK]', $kana);
test_ok('[\p{HalfKana}\pH\pK]',  $kana);
test_no('[^\p{HalfKana}\pH\pK]', $kana);
test_ok('[\p{HalfKana}\p{FullKana}]',  $kana);
test_no('[^\p{HalfKana}\p{FullKana}]', $kana);

# 441-450
test_ok('\p0',          $kanji0);
test_ok('\p{kanji0}',   $kanji0);
test_ok('[[:kanji0:]]', $kanji0);
test_ok('[ÅV-ÅZ]',      $kanji0);
test_no('\P0',          $kanji0);
test_no('\P{kanji0}',   $kanji0);
test_no('[[:^kanji0:]]',$kanji0);
test_no('[^ÅV-ÅZ]',     $kanji0);
test_ok('[\x{8156}-\x{815A}]', $kanji0);
test_no('[^\x{8156}-\x{815A}]',$kanji0);

# 451-460
test_ok('\p1',          $kanji1);
test_ok('\p{kanji1}',   $kanji1);
test_ok('[[:kanji1:]]', $kanji1);
test_ok('[àü-òr]',      $kanji1);
test_no('\P1',          $kanji1);
test_no('\P{kanji1}',   $kanji1);
test_no('[[:^kanji1:]]',$kanji1);
test_no('[^àü-òr]',     $kanji1);
test_ok('[\x{889F}-\x{9872}]',  $kanji1);
test_no('[^\x{889F}-\x{9872}]', $kanji1);

# 461-470
test_ok('\p2',          $kanji2);
test_ok('\p{kanji2}',   $kanji2);
test_ok('[[:kanji2:]]', $kanji2);
test_ok('[òü-Í§]',      $kanji2);
test_no('\P2',          $kanji2);
test_no('\P{kanji2}',   $kanji2);
test_no('[[:^kanji2:]]',$kanji2);
test_no('[^òü-Í§]',     $kanji2);
test_ok('[\x{989F}-\x{EAA4}]',  $kanji2);
test_no('[^\x{989F}-\x{EAA4}]', $kanji2);

# 471-478
test_ok('\p{kanji}',   $kanji);
test_ok('[\p{kanji}]', $kanji);
test_ok('[[:kanji:]]', $kanji);
test_ok('[\p0\p1\p2]', $kanji);
test_no('\P{kanji}',   $kanji);
test_no('[\P{kanji}]', $kanji);
test_no('[[:^kanji:]]',$kanji);
test_no('[^\p0\p1\p2]',$kanji);

# 479-486
test_ok('\p{BoxDrawing}',      $boxdrawing);
test_ok('[[:boxdrawing:]]',    $boxdrawing);
test_ok('[Ñü-Ñæ]',             $boxdrawing);
test_ok('[\x{849F}-\x{84BE}]', $boxdrawing);
test_no('\P{BoxDrawing}',      $boxdrawing);
test_no('[[:^boxdrawing:]]',   $boxdrawing);
test_no('[^Ñü-Ñæ]',            $boxdrawing);
test_no('[^\x{849F}-\x{84BE}]',$boxdrawing);

# 487-492
test_ok('[\x{824F}-\x{8258}]',  $fw_digit);
test_no('[^\x{824F}-\x{8258}]', $fw_digit);
test_ok('[\x{8260}-\x{8279}]',  $fw_upper);
test_no('[^\x{8260}-\x{8279}]', $fw_upper);
test_ok('[\x{8281}-\x{829A}]',  $fw_lower);
test_no('[^\x{8281}-\x{829A}]', $fw_lower);

# 493-500
test_ok('[\pJ\pV]',     $mswin);
test_ok('[\pJ\pN\pI]',  $mswin);
test_no('[^\pJ\pV]',    $mswin);
test_no('[^\pJ\pN\pI]', $mswin);
test_ok('[\p{JIS}\p{Vendor}]',     $mswin);
test_ok('[\p{JIS}\p{NEC}\p{IBM}]', $mswin);
test_no('[^\p{JIS}\p{Vendor}]',    $mswin);
test_no('[^\p{JIS}\p{NEC}\p{IBM}]',$mswin);

