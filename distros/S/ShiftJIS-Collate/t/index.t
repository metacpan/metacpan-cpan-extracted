use strict;
use vars qw($loaded);
$^W = 1;

BEGIN { $| = 1; print "1..16\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::Collate;
$loaded = 1;
print "ok 1\n";

####

my ($mod, $k, $kstr, $match, @tmp, @pos);
$mod = "ShiftJIS::Collate";
$kstr = "* ひらがな  とカタカナはレベル３では等しいかな。";
$k = "かな";

@pos = (position_in_bytes => 1);

if (@tmp = $mod->new(@pos, level => 1)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'がな' ? "ok" : "not ok", " 2\n";

if (@tmp = $mod->new(@pos, level => 2)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
  print $match eq 'カナ' ? "ok" : "not ok", " 3\n";

if (@tmp = $mod->new(@pos, level => 3)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'カナ' ? "ok" : "not ok", " 4\n";

if (@tmp = $mod->new(@pos, level => 4)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'かな' ? "ok" : "not ok", " 5\n";

if (@tmp = $mod->new(@pos, level => 5)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'かな' ? "ok" : "not ok", " 6\n";

$kstr = "* ひらｶﾞな  とカタカナはレベル３では等しいかな。";
$k = "かな";

if (@tmp = $mod->new(@pos, level => 1)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'ｶﾞな' ? "ok" : "not ok", " 7\n";

$kstr = "* ひらがなとカタカナはレベル３では等しいかな。";
$k = "ｶﾞﾅ";

if (@tmp = $mod->new(@pos, level => 1)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'がな' ? "ok" : "not ok", " 8\n";

$kstr = "* ひらがなとカタカナはレベル３では等しいかな。";
$k = "ｶﾞﾅ";

$match = undef;
if (@tmp = $mod->new(@pos, level => 4)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print ! defined $match ? "ok" : "not ok", " 9\n";

$kstr = 'パールプログラミング';
$k = 'アルふ';

$match = undef;
if (@tmp = $mod->new(@pos, level => 1)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'ールプ' ? "ok" : "not ok", " 10\n";

$match = undef;
if (@tmp = $mod->new(@pos, level => 3)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print ! defined $match ? "ok" : "not ok", " 11\n";

$kstr = 'ﾊﾟｰﾙﾌﾟﾛｸﾞﾗﾐﾝｸﾞ'; # 'ｸﾞ' is a single grapheme.
$k = 'ﾌﾟﾛｸ';

$match = undef;
if (@tmp = $mod->new(@pos, level => 1)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'ﾌﾟﾛｸﾞ' ? "ok" : "not ok", " 12\n";

$match = undef;
if (@tmp = $mod->new(@pos, level => 2)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print ! defined $match ? "ok" : "not ok", " 13\n";


$kstr = 'ﾊﾟｰﾙﾌﾟﾛｸﾞﾗﾐﾝｸﾞ';
$k = 'ﾟﾛｸ';
# 'ﾟ' is treated as a grapheme only when it can't combin with preceding kana.
# but it's ignorable.

$match = undef;
if (@tmp = $mod->new(@pos, level => 1)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'ﾛｸﾞ' ? "ok" : "not ok", " 14\n";

$kstr = 'ﾊﾟｰﾙふﾟﾛｸﾞﾗﾐﾝｸﾞ';
$k = 'ﾟﾛｸ';

$match = undef;
if (@tmp = $mod->new(@pos, level => 1)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq 'ﾛｸﾞ' ? "ok" : "not ok", " 15\n";

$kstr = "う、んー\0\0\0ー\0┘。";
$k = 'ﾝﾝ｡';

$match = undef;
if (@tmp = $mod->new(@pos, level => 2)->index($kstr, $k)) {
    $match = substr($kstr, $tmp[0], $tmp[1]);
}
print $match eq "ー\0\0\0ー\0┘。" ? "ok" : "not ok", " 16\n";
