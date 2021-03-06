use strict;
use vars qw($loaded);
$^W = 1;

BEGIN { $| = 1; print "1..58\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::Collate;
$loaded = 1;
print "ok 1\n";

####

my $mod = "ShiftJIS::Collate";

my $Collator = $mod->new();

my $s;

my @data = (
 [qw/ いぬ キツネ さる たぬき ネコ ねずみ パンダ ひょう ライオン /],
 [qw/ データ デェタ デエタ データー データァ データア
   デェター デェタァ デェタア デエター デエタァ デエタア /],
 [qw/ さと さど さとう さどう さとうや サトー さとおや /],
 [qw/ ファール ぶあい ファゥル ファウル ファン ふあん フアン ぶあん /],
 [qw/ しょう しよう じょう じよう しょうし しょうじ しようじ
      じょうし じょうじ ショー ショオ ジョー じょおう ジョージ /],
 [qw/すす すず すゝき すすき す┼ゞき すずき すずこ /],
);

$s = 0;
for(@data){
  my %h;
  @h{ @$_ } =();
  $s ++ unless join(":", @$_) eq join(":", $Collator->sort(keys %h));
}
print ! $s ? "ok" : "not ok", " 2\n";

print $Collator->cmp("Perl", "Ｐｅｒｌ") == 0
   && $mod->new( level => 4 )->cmp("Perl", "Ｐｅｒｌ") == 0
   && $mod->new( level => 5 )->cmp("Perl", "Ｐｅｒｌ") == -1
    ? "ok" : "not ok", " 3\n";

print $Collator->cmp("PERL", "Ｐｅｒｌ") == 1
   && $mod->new( level => 3 )->cmp("PERL", "Ｐｅｒｌ") == 1
   && $mod->new( level => 2 )->cmp("PERL", "Ｐｅｒｌ") == 0
    ? "ok" : "not ok", " 4\n";

print $Collator->cmp("Perl", "ＰＥＲＬ") == -1
   && $mod->new( level => 3 )->cmp("Perl", "ＰＥＲＬ") == -1
   && $mod->new( level => 2 )->cmp("Perl", "ＰＥＲＬ") == 0
    ? "ok" : "not ok", " 5\n";

print $Collator->cmp("あいうえお", "アイウエオ") == -1
    ? "ok" : "not ok", " 6\n";

print $mod->new( level => 3 )->cmp("あいうえお", "アイウエオ") == 0
   && $mod->new( katakana_before_hiragana => 1 )
          ->cmp("あいうえお", "アイウエオ") == 1
   && $mod->new( katakana_before_hiragana => 1,
            level => 3 )->cmp("あいうえお", "アイウエオ") == 0
    ? "ok" : "not ok", " 7\n";

print $Collator->cmp("perl", "PERL") == -1
   && $mod->new( level => 2 )->cmp("perl", "PERL") == 0
    ? "ok" : "not ok", " 8\n";

print $mod->new(upper_before_lower => 1)->cmp("perl", "PERL") == 1
    ? "ok" : "not ok", " 9\n";

print $mod->new(upper_before_lower => 1, level => 2)->cmp("perl", "PERL") == 0
    ? "ok" : "not ok", " 10\n";

print $Collator->cmp("ｱｲｳｴｵ", "アイウエオ") == 0
    ? "ok" : "not ok", " 11\n";

print $mod->new( level => 5 )->cmp("ｱｲｳｴｵ", "アイウエオ") == 1
    ? "ok" : "not ok", " 12\n";

print $Collator->cmp("XYZ", "abc") == 1
    ? "ok" : "not ok", " 13\n";

print $mod->new( level => 1 )->cmp("XYZ", "abc") == 1
    ? "ok" : "not ok", " 14\n";

print $Collator->cmp("XYZ", "ABC") == 1
   && $Collator->cmp("xyz", "ABC") == 1
    ? "ok" : "not ok", " 15\n";

print $Collator->gt("ああ", "あゝ")
   && $Collator->ge("ああ", "あゝ")
   && $Collator->ne("ああ", "あゝ")
    ? "ok" : "not ok", " 16\n";

print $mod->new( level => 3 )->gt("ああ", "あゝ")
   && $mod->new( level => 3 )->ge("ああ", "あゝ")
   && $mod->new( level => 3 )->ne("ああ", "あゝ")
   && $mod->new( level => 3 )->lt("あぁ", "あゝ")
   && $mod->new( level => 3 )->le("あぁ", "あゝ")
   && $mod->new( level => 3 )->ne("あぁ", "あゝ")
    ? "ok" : "not ok", " 17\n";

print $mod->new( level => 2 )->eq("ああ", "あゝ")
   && $mod->new( level => 2 )->ge("ああ", "あゝ")
   && $mod->new( level => 2 )->le("ああ", "あゝ")
   && $mod->new( level => 1 )->lt("ああ", "あゞ")
   && $mod->new( level => 1 )->le("ああ", "あゞ")
   && $mod->new( level => 1 )->ne("ああ", "あゞ")
    ? "ok" : "not ok", " 18\n";

print $mod->new( level => 2 )->gt("ただ", "たゝ")
   && $mod->new( level => 2 )->ge("ただ", "たゝ")
   && $mod->new( level => 2 )->ne("ただ", "たゝ")
   && $mod->new( level => 2 )->eq("ただ", "たゞ")
   && $mod->new( level => 2 )->ge("ただ", "たゞ")
   && $mod->new( level => 2 )->le("ただ", "たゞ")
    ? "ok" : "not ok", " 19\n";

print $mod->new( level => 1 )->eq("ただ", "たゝ")
   && $mod->new( level => 1 )->ge("ただ", "たゝ")
   && $mod->new( level => 1 )->le("ただ", "たゝ")
    ? "ok" : "not ok", " 20\n";

print $Collator->cmp("パアル", "パール") == 1
    ? "ok" : "not ok", " 21\n";

print $mod->new( level => 3 )->cmp("パアル", "パール") == 1
   && $mod->new( level => 3 )->cmp("パァル", "パール") == 1
   && $mod->new( level => 2 )->cmp("パアル", "パール") == 0
    ? "ok" : "not ok", " 22\n";

print $Collator->cmp("", "") == 0
    ? "ok" : "not ok", " 23\n";

print $mod->new( level => 1 )->cmp("", "") == 0
   && $mod->new( level => 2 )->cmp("", "") == 0
   && $mod->new( level => 3 )->cmp("", "") == 0
   && $mod->new( level => 4 )->cmp("", "") == 0
   && $mod->new( level => 5 )->cmp("", "") == 0
    ? "ok" : "not ok", " 24\n";

print $Collator->cmp("", " ")  == -1
   && $Collator->cmp("", "\n") == 0
   && $Collator->cmp("\n ", "\n \r") == 0
   && $Collator->cmp(" ", "\n \r") == 0
    ? "ok" : "not ok", " 25\n";

print $Collator->cmp('Ａ', '亜') == -1
    ? "ok" : "not ok", " 26\n";

print $mod->new( level => 1, kanji => 1 )->cmp('Ａ', '亜') == 1
   && $mod->new( level => 1, kanji => 1 )->cmp('Ａ', '仝') == -1
   && $mod->new( level => 1, kanji => 1 )->cmp('仝', '亜') == 1
   && $mod->new( level => 1, kanji => 2 )->cmp('Ａ', '亜') == -1
   && $mod->new( level => 1, kanji => 2 )->cmp('Ａ', '仝') == -1
   && $mod->new( level => 1, kanji => 2 )->cmp('仝', '亜') == -1
   && $mod->new( level => 1, kanji => 0 )->cmp('亜', '一') == -1
   && $mod->new( level => 1, kanji => 1 )->cmp('亜', '一') == 0
   && $mod->new( level => 1, kanji => 2 )->cmp('亜', '一') == -1
    ? "ok" : "not ok", " 27\n";

print $Collator->cmp('〓', '熙') == 1
    ? "ok" : "not ok", " 28\n";

{
  my(@subject, $sorted);

  my $delProlong = sub {
      my $str = shift;
      $str =~ s/\G(
	(?:[\x00-\x7F\xA1-\xDF]|[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC])*?
	)\x81\x5B/$1/gox;
      $str;
    };

  my $delete_prolong = $mod->new(preprocess => $delProlong);

  my $ignore_prolong = $mod->new(ignoreChar => '^(?:\x81\x5B|\xB0)');

  my $jis    = new ShiftJIS::Collate;
  my $level2 = new ShiftJIS::Collate level => 2;
  my $level3 = new ShiftJIS::Collate level => 3;
  my $level4 = new ShiftJIS::Collate level => 4;
  my $level5 = new ShiftJIS::Collate level => 5;

  $sorted  = 'パイナップル ハット はな バーナー バナナ パール パロディ';
  @subject = qw(パロディ パイナップル バナナ ハット はな パール バーナー);

  print
      $sorted eq join(' ', $ignore_prolong->sort(@subject))
   && $sorted eq join(' ', $delete_prolong->sort(@subject))
   && $level2->cmp("パアル", "パール") == 0
   && $level3->cmp("パアル", "パール") == 1
   && $level3->cmp("パァル", "パール") == 1
   && $level4->cmp("ﾊﾟｰﾙ",   "パール") == 0
   && $level5->cmp("パール", "ﾊﾟｰﾙ",4) == -1
   && $level2->cmp("パパ", "ぱぱ") == 0
   && $jis->cmp("パパ", "ぱぱ") == 1
    ? "ok" : "not ok", " 29\n";
}


{
  my @hira = map "\x82".chr, 0x9F .. 0xF1;
  my @kata = map "\x83".chr, 0x40 .. 0x7E, 0x80 .. 0x96;
  my $i;

  my $jis = new ShiftJIS::Collate;
  my $kbh = new ShiftJIS::Collate katakana_before_hiragana => 1;
  my $lv3 = new ShiftJIS::Collate level => 3;

  for($i = 0; $i < @hira; $i++) {
    last unless $jis->le($hira[$i], $kata[$i]);
    last unless $kbh->ge($hira[$i], $kata[$i]);
    last unless $lv3->eq($hira[$i], $kata[$i]);
  }

  print $i == @hira ? "ok" : "not ok", " 30\n";
}

{
  my @lower = map "\x82".chr, 0x81 .. 0x9A;
  my @upper = map "\x82".chr, 0x60 .. 0x79;
  my $i;

  my $jis = new ShiftJIS::Collate;
  my $ubl = new ShiftJIS::Collate upper_before_lower => 1;
  my $lv2 = new ShiftJIS::Collate level => 2;
  my $lv3 = new ShiftJIS::Collate level => 3;
  my $ul3 = new ShiftJIS::Collate level => 3, upper_before_lower => 1;

  for($i = 0; $i < @lower; $i++) {
    last unless $jis->le($lower[$i], $upper[$i]);
    last unless $ubl->ge($lower[$i], $upper[$i]);
    last unless $lv2->eq($lower[$i], $upper[$i]);
    last unless $lv3->le($lower[$i], $upper[$i]);
    last unless $ul3->ge($lower[$i], $upper[$i]);
  }

  print $i == @lower ? "ok" : "not ok", " 31\n";
}

my $obs; # 'overrideCJK' is obsolete and to be croaked.
eval { $obs = new ShiftJIS::Collate overrideCJK => sub {}, level => 3; };

print $@ ? "ok" : "not ok", " 32\n";

print 1
   && $mod->new( level => 3 )->gt('ハハハハ', 'ハヽヽヽ')
   && $mod->new( level => 2 )->eq('ハハハハ', 'ハヽヽヽ')
   && $mod->new( level => 3 )->gt('キイイイ', 'キーーー')
   && $mod->new( level => 2 )->eq('キイイイ', 'キーーー')
    ? "ok" : "not ok", " 33\n";

##########

my (@source, $result);

@source = (
  ['永田', 'ながた'],
  ['小山', 'おやま'],
  ['長田', 'おさだ'],
  ['長田', 'ながた'],
  ['小山', 'こやま'],
);

$result = join ';', map join(',', @$_), $Collator->sortYomi(@source);

print $result eq
  '長田,おさだ;小山,おやま;小山,こやま;永田,ながた;長田,ながた'
? "ok" : "not ok", " 34\n";

@source = (
  ['澤島',   'さわしま'],
  ['４面体', 'しめんたい'],
  ['河田',   'かわだ'],
  ['土井',   'つちい'],
  ['α崩壊', 'アルファほうかい'],
  ['Γ関数', 'ガンマかんすう'],
  ['Perl',   'パール'],
  ['４次元', 'よじげん'],
  ['β線',   'ベータせん'],
  ['角田',   'かくた'],
  ['沢島',   'さわしま'],
  ['河内',   'かわち'],
  ['沢田',   'さわだ'],
  ['河内',   'こうち'],
  ['２色性', 'にしょくせい'],
  ['澤田',   'さわだ'],
  ['土井',   'どい'],
  ['Ｑ値',   'キューち'],
  ['河西',   'かさい'],
  ['澤嶋',   'さわしま'],
  ['ＪＩＳ', 'じす'],
  ['関東',   'かんとう'],
  ['河辺',   'かわべ'],
  ['沢嶋',   'さわしま'],
  ['角田',   'かどた'],
  ['土居',   'つちい'],
  ['６面体', 'ろくめんたい'],
  ['角田',   'つのだ'],
  ['土居',   'どい'],
  ['河合',   'かわい'],
);

$result = join ';', map join(',', @$_), $Collator->sortDaihyo(@source);

print $result eq
  '４面体,しめんたい;２色性,にしょくせい;４次元,よじげん;' .
  '６面体,ろくめんたい;α崩壊,アルファほうかい;Γ関数,ガンマかんすう;' .
  'β線,ベータせん;Ｑ値,キューち;ＪＩＳ,じす;Perl,パール;河西,かさい;' .
  '河合,かわい;河田,かわだ;河内,かわち;河辺,かわべ;角田,かくた;' .
  '角田,かどた;関東,かんとう;河内,こうち;沢島,さわしま;沢嶋,さわしま;' .
  '沢田,さわだ;澤島,さわしま;澤嶋,さわしま;澤田,さわだ;角田,つのだ;' .
  '土井,つちい;土居,つちい;土井,どい;土居,どい'
? "ok" : "not ok", " 35\n";


sub toU {
    my $char = shift;
    return $char eq '一' ? 0x4E00 :
	   $char eq '亜' ? 0x4E9C : 0x9999;
}

print $Collator->lt('Ａ', '亜')
    ? "ok" : "not ok", " 36\n";

print $mod->new( level => 1, kanji => 1 )->gt('Ａ', '亜')
   && $mod->new( level => 1, kanji => 1 )->lt('Ａ', '仝')
   && $mod->new( level => 1, kanji => 1 )->gt('仝', '亜')
   && $mod->new( level => 1, kanji => 1 )->eq('亜', '一')
    ? "ok" : "not ok", " 37\n";

print $mod->new( level => 1, kanji => 0 )->lt('亜', '一')
   && $mod->new( level => 1, kanji => 2 )->lt('Ａ', '亜')
   && $mod->new( level => 1, kanji => 2 )->lt('Ａ', '仝')
   && $mod->new( level => 1, kanji => 2 )->lt('仝', '亜')
   && $mod->new( level => 1, kanji => 2 )->lt('亜', '一')
    ? "ok" : "not ok", " 38\n";

print $mod->new( level => 1, kanji => 3, tounicode => \&toU )->lt('Ａ', '亜')
   && $mod->new( level => 1, kanji => 3, tounicode => \&toU )->lt('Ａ', '仝')
   && $mod->new( level => 1, kanji => 3, tounicode => \&toU )->lt('仝', '亜')
   && $mod->new( level => 1, kanji => 3, tounicode => \&toU )->gt('亜', '一')
    ? "ok" : "not ok", " 39\n";

print $Collator->lt('━', '　') ? "ok" : "not ok", " 40\n";
print $Collator->lt('　', '〃') ? "ok" : "not ok", " 41\n";
print $Collator->lt('〃', '仝') ? "ok" : "not ok", " 42\n";
print $Collator->lt('仝', '々') ? "ok" : "not ok", " 43\n";
print $Collator->lt('々', '〆') ? "ok" : "not ok", " 44\n";
print $Collator->lt('〆', '〇') ? "ok" : "not ok", " 45\n";
print $Collator->lt('〇', '亜') ? "ok" : "not ok", " 46\n";
print $Collator->lt('亜', '熙') ? "ok" : "not ok", " 47\n";
print $Collator->lt('熙', '〓') ? "ok" : "not ok", " 48\n";


print $Collator->eq('', '゛') ? "ok" : "not ok", " 49\n";
print $Collator->eq('', '゜') ? "ok" : "not ok", " 50\n";
print $Collator->eq('', 'ﾞﾟ') ? "ok" : "not ok", " 51\n";
print $Collator->eq('', 'ﾟﾞ') ? "ok" : "not ok", " 52\n";
print $Collator->eq('', '◯') ? "ok" : "not ok", " 53\n";

my $box = join('', pack 'n*', 0x849f..0x84be);
print $Collator->eq('',  $box) ? "ok" : "not ok", " 54\n";
print $Collator->gt('a', $box) ? "ok" : "not ok", " 55\n";
print $Collator->lt('a'.$box, $box.'b') ? "ok" : "not ok", " 56\n";
print $Collator->eq('a'.$box, $box.'a') ? "ok" : "not ok", " 57\n";
print $Collator->gt('b'.$box, $box.'a') ? "ok" : "not ok", " 58\n";

