use strict;
use vars qw($i $loaded $num);
BEGIN {
  use ShiftJIS::Collate;
  $| = 1;
  $num = 10 + 1;
  print "1..$num\n";
}
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";

my $Collator = new ShiftJIS::Collate;

chomp(my @data = <DATA>);
unshift @data, "";
my $data = join ":",@data;

for $i (2..$num){
  my @arr  = shuffle(@data);
  my $arr  = join ":",@arr;
  my @sort = $Collator->sort(@arr);
  my $sort = join ":",@sort;
  print $sort eq $data ? "ok" : "not ok", " $i\n";
}

sub shuffle {
  my @array = @_;
  my $i;
  for ($i = @array; --$i; ) {
     my $j = int rand ($i+1);
     next if $i == $j;
     @array[$i,$j] = @array[$j,$i];
  }
  return @array;
}

1;
__DATA__
∞ｒ∞
∞Ｒ＃
∞ｔ∞
＃ｒ∞
＃Ｒ＃
＃ｔ％
＃Ｔ％
８ｔ∞
８Ｔ∞
８ｔ＃
８Ｔ＃
８ｔ％
８Ｔ％
８ｔ８
８Ｔ８
ωｒ∞
ΩＲ％
ｒｒ∞
ｒＲ∞
Ｒｒ∞
ＲＲ∞
ＲＴ％
ｒｔ８
ｔｒ∞
ｔｒ８
ＴＲ８
ｔｔ８
シャーレ
シャイ
シヤィ
シャレ
ちょこ
ちよこ
チョコレート
てーた
テータ
テェタ
てえた
でーた
データ
デェタ
でえた
テータｇ
てぇたｇ
てぇたＧ
テェタＧ
てーたー
テータァ
てーたあ
テェター
てぇたぁ
てえたー
でーたー
データァ
でェたァ
デぇタぁ
デエタア
ひゆ
びゅあ
ぴゅあ
びゅあー
ビュアー
ぴゅあー
ピュアー
ヒュウ
ヒユウ
ビュウア
びゅーあー
ビューアー
ビュウアー
ひゅん
ぴゅん
ふーり
フーリ
ふぅり
ふゥり
ふゥリ
フウリ
ぶーり
ブーリ
ぶぅり
ブゥり
ぷうり
プウリ
ふーりー
フゥリー
ふゥりィ
フぅリぃ
フウリー
ふうりぃ
ブウリイ
ぷーりー
ぷゥりイ
ぷうりー
プウリイ
フヽ
ふゞ
ぶゝ
ぶふ
ぶフ
ブふ
ブフ
ぶゞ
ぶぷ
ブぷ
ぷゝ
プヽ
ぷふ
