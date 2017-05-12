
use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..129\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::Regexp qw(:all);
$loaded = 1;
print "ok 1\n";

#########

print !match("Perl", "perl")          ? "ok" : "not ok", " 2\n";
print  match("PERL", '^(?i)perl$')    ? "ok" : "not ok", " 3\n";
print  match("PErl", '^perl$', 'i')   ? "ok" : "not ok", " 4\n";
print  match("Perl講習", '^perl講習$', 'i')    ? "ok" : "not ok", " 5\n";
print !match("Perl講縮", '^perl講習$', 'i')    ? "ok" : "not ok", " 6\n";
print !match('エ', 'ト', 'i')        ? "ok" : "not ok", " 7\n";
print !match('エ', '(?i)ト')         ? "ok" : "not ok", " 8\n";
print  $] < 5.005 ||
     ( match("Perl講習", '^(?i:perl講習)$')
   && !match("Perl講縮", '^(?i:perl講習)$'))
    ? "ok" : "not ok", " 9\n";

print  match("運転免許", "運転")     ? "ok" : "not ok", " 10\n";
print !match("ヤカン", "ポット")     ? "ok" : "not ok", " 11\n";
print !match("ヤカン", "や[か]ん")   ? "ok" : "not ok", " 12\n";
print  match("ヤカン", "や[か]ん", 'j')    ? "ok" : "not ok", " 13\n";
print  match('らくだ本', 'ラくだ', 'j')    ? "ok" : "not ok", " 14\n";
print  match('らくだ本', '(?j)ラくだ')     ? "ok" : "not ok", " 15\n";
print  match('らくだ本', '^(?j)ラくだ')    ? "ok" : "not ok", " 16\n";
print  match('らくだ本', '\A(?j)ラくだ')   ? "ok" : "not ok", " 17\n";
print  match('らくだ本', '\G(?j)ラくだ')   ? "ok" : "not ok", " 18\n";
print  match("かゞり火", "カヾ", 'j')      ? "ok" : "not ok", " 19\n";
print  match("かゞり火", "(?j)カヾ")       ? "ok" : "not ok", " 20\n";
print  match("これはＰｅｒｌ", "ｐｅｒｌ", 'I')  ? "ok" : "not ok", " 21\n";
print  match("ΠεΡλ", "περλ", 'I')  ? "ok" : "not ok", " 22\n";
print  match("ΠεΡλ", "(?I)περλ", 'j')    ? "ok" : "not ok", " 23\n";
print  match('座標表示', (qw/表 /)[0] )    ? "ok" : "not ok", " 24\n";
print !match('Y座標', (qw/表 /)[0])        ? "ok" : "not ok", " 25\n";
print !match('＝@＝@ ==@', '　')           ? "ok" : "not ok", " 26\n";
print  match('あ', '')                     ? "ok" : "not ok", " 27\n";

print join('', match("あ\nい", '(^\j*)')) eq "あ\nい"
    ? "ok" : "not ok", " 28\n";
print join('', match("あ\nい", '(^\J*)')) eq "あ"
    ? "ok" : "not ok", " 29\n";
print join('', match("あ\nい", '(^\C\C{2})')) eq "あ\n"
    ? "ok" : "not ok", " 30\n";
print join('', match("あABCD", '(^\J\C)')) eq "あA"
    ? "ok" : "not ok", " 31\n";
print join('', match("\xffあ\xe0", '(^\C\J)')) eq "\xffあ"
    ? "ok" : "not ok", " 32\n";

print  match('Aaあアｱ亜', '^\j{6}$')        ? "ok" : "not ok", " 33\n";
print  match('Aaあアｱ亜', '^\j{6}$', 's')   ? "ok" : "not ok", " 34\n";
print  match('Aaあアｱ亜', '^\j{6}$', 'm')   ? "ok" : "not ok", " 35\n";
print  match('Aaあアｱ亜'."\n", '^\j{6}$')   ? "ok" : "not ok", " 36\n";
print  match('Aaあアｱ亜'."\n", '^\j{6}$', 's')   ? "ok" : "not ok", " 37\n";
print  match('Aaあアｱ亜'."\n", '^\j{6}$', 'm')   ? "ok" : "not ok", " 38\n";
print  match('表示', <<'HERE', 'x')         ? "ok" : "not ok", " 39\n";
^表 .$
HERE

print  match('\　', '　$')            ? "ok" : "not ok", " 40\n";
print !match('\　', '^　$')           ? "ok" : "not ok", " 41\n";
print  match('　', '^\　$')           ? "ok" : "not ok", " 42\n";
print  match('　', '^\x{8140}$')      ? "ok" : "not ok", " 43\n";
print  match('あ', '^\x{82A0}$')      ? "ok" : "not ok", " 44\n";
print  match('あ', '^[\x{81fc}-\x{8340}]$')      ? "ok" : "not ok", " 45\n";
print  match(' ',  '^\x20$')          ? "ok" : "not ok", " 46\n";
print  match('  ',  '^ \040	\ $	 ','x')  ? "ok" : "not ok", " 47\n";
print !match("a b",  'a b', 'x')      ? "ok" : "not ok", " 48\n";
print  match("ab",  'a b', 'x')       ? "ok" : "not ok", " 49\n";
print  match("ab",  '(?iIjx)  a  b  ')     ? "ok" : "not ok", " 50\n";
print  match("a b",  'a\ b', 'x')     ? "ok" : "not ok", " 51\n";
print  match("a b",  'a[ ]b', 'x')    ? "ok" : "not ok", " 52\n";
print  match("\0",  '^\0$')           ? "ok" : "not ok", " 53\n";

print  match('--\\--', '\\\\')        ? "ok" : "not ok", " 54\n";
print  match('あいううう', '^..う{3}$')       ? "ok" : "not ok", " 55\n";
print  match('あいううう', '^あいう{3}$')     ? "ok" : "not ok", " 56\n";
print  match('あいいううう', '^あい+う{3}$')  ? "ok" : "not ok", " 57\n";
print  match('アイウウウ', '^アイウ{3}$')     ? "ok" : "not ok", " 58\n";
print  match('アイウウウ', '^アイウ{3}$', 'i')    ? "ok" : "not ok", " 59\n";
print !match('アイCウウウ', '^アイcウ{3}$')   ? "ok" : "not ok", " 60\n";
print !match('', '^アイcウ{3}$')              ? "ok" : "not ok", " 61\n";
print  match("aaa\x1Caaa", '[\c\]')           ? "ok" : "not ok", " 62\n";
print  match('アイCウウウ', '^アイcウ{3}$', 'i')  ? "ok" : "not ok", " 63\n";
print  match("あいう09", '^\pH{3}\pD{2}$')    ? "ok" : "not ok", " 64\n";
print  $] < 5.005 || match("あお１２", '(?<=\pH{2})\pD{2}')
    ? "ok" : "not ok", " 65\n";

use vars qw($aiu);
$aiu = "!あい--うえお00";
print "!＃＃--＃＃＃00" eq replace($aiu, '[\pH]', '\x{8194}', 'g')
    ? "ok" : "not ok", " 66\n";
print "!＃＃--＃＃＃00" eq replace($aiu, '[\p{Hiragana}]', '\x{8194}', 'g')
    ? "ok" : "not ok", " 67\n";
print "!＃い--うえお00" eq replace($aiu, '\p{Hiragana}', '＃')
    ? "ok" : "not ok", " 68\n";
print "!あいあい--うえおうえお00" eq replace($aiu, '(\pH+)', '${1}${1}', 'g')
    ? "ok" : "not ok", " 69\n";
print "!あいあい--うえお00" eq replace($aiu, '(\pH+)', '${1}${1}')
    ? "ok" : "not ok", " 70\n";


print "あ\\0い\\0あい" eq replace("あ\0い\0あい",'\0', '\\\\0', 'g')
    ? "ok" : "not ok", " 71\n";
print "=マミ=" eq replace('{マミ}', '\{|\}', '=', 'g')
    ? "ok" : "not ok", " 72\n";
print "あ\nい\nあい" eq replace("あ\0い\0あい",'\0', '\n', 'g')
    ? "ok" : "not ok", " 73\n";
print 'ｌ' eq (match("Ｐｅｒｌ",   '(\J)\Z'))[0]
    ? "ok" : "not ok", " 74\n";
print 'ｌ' eq (match("Ｐｅｒｌ\n", '(\J)\Z'))[0]
    ? "ok" : "not ok", " 75\n";
print "\n" eq (match("Ｐｅｒｌ\n", '(\j)\z'))[0]
    ? "ok" : "not ok", " 76\n";
print 'ｌ' eq (match("Ｐｅｒｌ",   '(\j)\z'))[0]
    ? "ok" : "not ok", " 77\n";
print 'チ' eq (match("マッチ",   '(\j)\z'))[0]
    ? "ok" : "not ok", " 78\n";
print 'かい' eq (match('たかい　かいろう', '(\PS+)\pS*\1'))[0]
    ? "ok" : "not ok", " 79\n";
print '試試試試E試試試試E' eq replace('試試試試E試試試試E', '殺', 'E', 'g')
    ? "ok" : "not ok", " 80\n";
print "a bDC123" eq replace("a b\n123", '$ \j', "DC", 'mx')
    ? "ok" : "not ok", " 81\n";
print "a bDC123" eq replace("a b\n123", '$\j', "DC", 'm')
    ? "ok" : "not ok", " 82\n";

print 'あ:いう:えおメ^' eq join(':', jsplit('／', 'あ／いう／えおメ^'))
    ? "ok" : "not ok", " 83\n";
print 'あ:いう＝@:えお　メ^' eq
      join(':', jsplit('\pS+', 'あ  いう＝@　えお　メ^', 3))
    ? "ok" : "not ok", " 84\n";
print '頭にポマード；キャ-;-ポポロ-;--;-ン アポロ' eq
      join('-;-', jsplit('\|', '頭にポマード；キャ|ポポロ||ン アポロ'))
    ? "ok" : "not ok", " 85\n";
print '頭に-マード；キャ|-ロン アポロ' eq
      join('-', jsplit('ポ+', '頭にポマード；キャ|ポポロン アポロ', 3))
    ? "ok" : "not ok", " 86\n";
print 'Perl-:-／-:-プログラム-:-／-:-パスワード' eq
      join('-:-', jsplit('(／)', 'Perl／プログラム／パスワード'))
    ? "ok" : "not ok", " 87\n";
print '-:-まつ-:-しまやああ-:-まつ-:-しまや-:-まつ-:-しまや' eq
      join('-:-', jsplit('(?j)(マツ)', 'まつしまやああまつしまやまつしまや'))
    ? "ok" : "not ok", " 88\n";
print '-:-、これ-:-みろ' eq
      join('-:-', jsplit('(?j)ヲ+', 'をを、これをみろ'))
    ? "ok" : "not ok", " 89\n";


use vars qw($asc);
$asc = "\0\x01\a\e\n\r\t\f"
    . q( !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ)
    . q([\]^_`abcdefghijklmnopqrstuvwxyz{|}~)."\x7F";

sub replace_ka { my($str, $re) = @_; replace($str, $re, 'ｶ', 'g') }
sub core_ka    { my($str, $re) = @_; $str =~ s/$re/ｶ/g; $str }
sub compare    { my $r = shift; replace_ka($asc, $r) eq core_ka($asc, $r) }

print compare('[\d]')         ? "ok" : "not ok", " 90\n";
print compare('[^\s]')        ? "ok" : "not ok", " 91\n";
print compare('[^!2]')        ? "ok" : "not ok", " 92\n";
print compare('[^#-&]')       ? "ok" : "not ok", " 93\n";
print compare('[^\/]')        ? "ok" : "not ok", " 94\n";
print compare('[[-\\\\]')     ? "ok" : "not ok", " 95\n";
print compare('[a-~]')        ? "ok" : "not ok", " 96\n";
print compare('[\a-\e]')      ? "ok" : "not ok", " 97\n";
print compare('[\a-\b]')      ? "ok" : "not ok", " 98\n";
print compare('[\a-v]')       ? "ok" : "not ok", " 99\n";
print compare('[!-@[-^`{-~]') ? "ok" : "not ok", " 100\n";

use vars qw($str $zen $jpn $perl);
$str  = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz123456789+-=";
$zen  = "ＡＢＣＤＥＦＧＨＩＪａｂｃｄｅｆｇｈｉｊ０１２３４";
$jpn  = "あいうえおかきくけこアイウエオカキクケコ０１２３４";
$perl = "ｐｅｒｌＰＥＲＬperlPERLぱあるパアル";

print "**CDEFGHIJKLMNO****TUVWXY***cdefghijklmno****tuvwxy*123456789+-="
       eq replace($str, '[abp-sz]', '*', 'ig')
    ? "ok" : "not ok", " 101\n";
print "***DEFGHIJKLMNOPQRSTUVWXYZ***defghijklmnopqrstuvwxyz123456789+-="
       eq replace($str, '[abc]', '*', 'ig')
    ? "ok" : "not ok", " 102\n";
print "**CDEFGHIJKLMNOPQRSTUVW*****cdefghijklmnopqrstuvw***123456789+-="
       eq replace($str, '[a-a_b-bx-z]', '*', 'ig')
    ? "ok" : "not ok", " 103\n";
print "ABCDEFGHI*KLMNOPQRSTUVWXYZabcdefghi*klmnopqrstuvwxyz123456789+-="
       eq replace($str, '\c*', '*', 'ig')
    ? "ok" : "not ok", " 104\n";

print "*BCDEFGHIJKLMNOPQRSTUVWXYZ*bcdefghijklmnopqrstuvwxyz*********+-*"
       eq replace($str, '[0-A]', '*', 'ig')
    ? "ok" : "not ok", " 105\n";
print "*************************************************************+-*"
       eq replace($str, '[0-a]', '*', 'ig')
    ? "ok" : "not ok", " 106\n";
print "****E******L***P*R************e******l***p*r********************"
       eq replace($str, '[^perl]', '*', 'ig')
    ? "ok" : "not ok", " 107\n";
print "あえおきくけこアエオキクケコ０１２３４"
       eq replace($jpn, '[うかい]', '', 'jg')
    ? "ok" : "not ok", " 108\n";
print "＃ｅｒ＃＃ＥＲ＃p＃rlP＃RLぱ＃るパ＃ル"
       eq replace($perl, '[ｐeあＬ]', '＃', 'iIjg')
    ? "ok" : "not ok", " 109\n";
print "＃ｅｒｌＰＥＲ＃p＃rlP＃RLぱ＃るパ＃ル"
       eq replace($perl, '[ｐeあＬ]', '＃', 'ijg')
    ? "ok" : "not ok", " 110\n";

print '##りび-#ﾙ#ﾓ-#ン#ルー' eq
    replace('かがりび-ｶﾙｶﾞﾓ-カンガルー', '[[=か=]]', '#', 'g')
    ? "ok" : "not ok", " 111\n";

print match('日本', '[[=日=]][[=本=]]')
    ? "ok" : "not ok", " 112\n";
print match('PｅrＬ', '^[[=p=]][[=Ｅ=]][[=ｒ=]][[=L=]]$')
    ? "ok" : "not ok", " 113\n";
print match('[a]', '^[[=[=]][[=\x41=]][[=]=]]$')
    ? "ok" : "not ok", " 114\n";
print match('-［Ａ］', '.[[=[=]][[=\x61=]][[=]=]]$')
    ? "ok" : "not ok", " 115\n";

print $] < 5.005 || 'ZアイウエZアZアイウZア泣A'
      eq replace('アイウエアアイウア泣A', '(?=ア)', 'Z', 'gz')
    ? "ok" : "not ok", " 116\n";
print $] < 5.005|| 'Z1Z2Z3Z1Z2Z3Z'
      eq replace('0123000123', '0*', 'Z', 'g')
    ? "ok" : "not ok", " 117\n";
print $] < 5.005 || "#\n#\n#a\n#bb\n#\n#cc\n#dd"
      eq replace("\n\na\nbb\n\ncc\ndd", '^', '#', 'mg')
    ? "ok" : "not ok", " 118\n";

print match('あい０１２３', '\A\pH{2}\pD*\z')
    ? "ok" : "not ok", " 119\n";
print match('あい０１２３', '\A\ph{2}\pd*\z')
    ? "ok" : "not ok", " 120\n";
print match('あい０１２３', '\A\p{hiragana}{2}\p{digit}{4}\z')
    ? "ok" : "not ok", " 121\n";
print match('あい０１２３', '\A\p{IsHiragana}{2}\p{IsDigit}{4}\z')
    ? "ok" : "not ok", " 122\n";
print match('あい０１２３', '\A\p{InHiragana}{2}\p{InDigit}{4}\z')
    ? "ok" : "not ok", " 123\n";

# A range must not match an illegal char.
print  match("\x84\x7e", "[\x84\x70-\x85\x50]")  ? "ok" : "not ok", " 124\n";
print !match("\x84\x7f", "[\x84\x70-\x85\x50]")  ? "ok" : "not ok", " 125\n";
print  match("\x84\xfc", "[\x84\x70-\x85\x50]")  ? "ok" : "not ok", " 126\n";
print !match("\x84\xff", "[\x84\x70-\x85\x50]")  ? "ok" : "not ok", " 127\n";
print !match("\x85\x10", "[\x84\x70-\x85\x50]")  ? "ok" : "not ok", " 128\n";
print  match("\x85\x40", "[\x84\x70-\x85\x50]")  ? "ok" : "not ok", " 129\n";

