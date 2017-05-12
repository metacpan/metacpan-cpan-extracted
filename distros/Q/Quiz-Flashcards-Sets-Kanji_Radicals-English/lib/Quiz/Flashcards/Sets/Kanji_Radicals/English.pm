package Quiz::Flashcards::Sets::Kanji_Radicals::English;

use warnings;
use strict;
use utf8;

use base 'Exporter';

our @EXPORT = (qw( get_set ));

=head1 NAME

Quiz::Flashcards::Sets::Kanji_Radicals::English - Flashcard set with the basic 214 japanese radicals

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

This module will provide L<Quiz::Flashcards> with the data needed to test and train the reading (meaning) of the 214 basic radicals of the japanese kanji alphabet.

The characters are presented in UTF8 text, so your system will need to have compatible fonts installed. The answer is expected as multiple choice input. Upon confirmation of the answer the set will attempt to play a sound of the word if L<Quiz::Flashcards::Audiobanks::Japanese_Syllables> is installed.

=head1 SYNOPSIS

This module is used by L<Quiz::Flashcards> and not on its own. Refer to the source code of L<Quiz::Flashcards> for examples on how to access it.

=head1 FUNCTIONS

=head2 get_set

This function returns an array of all items in this set. The items are represented as hashes with the following members: C<question>, C<answer>, C<question_type>, C<answer_type>, C<audiobank>, C<audio_file>.

=cut

=head1 AUTHOR

Christian Walde, C<< <mithaldu at yahoo.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Quiz-flashcards-sets-kanji_radicals-english at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Quiz-Flashcards-Sets-Kanji_Radicals-English>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

Please refer to L<Quiz::Flashcards> for further information.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Christian Walde, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

my $ab = "Quiz::Flashcards::Audiobanks::Japanese_Words_Radicals";
my $ab2 = "Quiz::Flashcards::Audiobanks::Japanese_Syllables";

my @set;
push @set, { question => "一", complexity => 1, answer => "one ", description => "いち", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ichi.wav"   };
push @set, { question => "丨", complexity => 1, answer => "rod / staff / line radical ", description => "ぼう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "bou.wav"   };
push @set, { question => "丶", complexity => 1, answer => "dot ", description => "てん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ten.wav"   };
push @set, { question => "丿", complexity => 1, answer => "slash / katakana 'no' ", description => "の", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "no.wav"   };
push @set, { question => "乙", complexity => 1, answer => "fish hook radical / second / strange ", description => "おつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "otsu.wav"   };
push @set, { question => "乚", complexity => 2, answer => "fish hook radical / second / strange ", description => "おつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "otsu.wav"   };
push @set, { question => "乛", complexity => 3, answer => "fish hook radical / second / strange ", description => "おつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "otsu.wav"   };
push @set, { question => "亅", complexity => 1, answer => "hook / barb radical ", description => "けつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ketsu.wav"   };
push @set, { question => "二", complexity => 1, answer => "two ", description => "に", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ni.wav"   };
push @set, { question => "亠", complexity => 1, answer => "pot lid ", description => "とう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tou.wav"   };
push @set, { question => "人", complexity => 1, answer => "person ", description => "ひと", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hito.wav"   };
push @set, { question => "亻", complexity => 2, answer => "person ", description => "ひと", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hito.wav"   };
push @set, { question => "儿", complexity => 2, answer => "human legs ", description => "じん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "jin.wav"   };
push @set, { question => "入", complexity => 2, answer => "enter ", description => "はいり", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hairi.wav"   };
push @set, { question => "八", complexity => 2, answer => "eight ", description => "はち", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hachi.wav"   };
push @set, { question => "冂", complexity => 2, answer => "upside down box radical ", description => "きょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kyou.wav"   };
push @set, { question => "冖", complexity => 2, answer => "cover ", description => "べき", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "beki.wav"   };
push @set, { question => "冫", complexity => 2, answer => "ice radical ", description => "ひょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hyou.wav"   };
push @set, { question => "几", complexity => 2, answer => "table / desk ", description => "き", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ki.wav"   };
push @set, { question => "凵", complexity => 3, answer => "open box enclosure", description => "かん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kan.wav"   };
push @set, { question => "刀", complexity => 3, answer => "sword / blade ", description => "かたな", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "katana.wav"   };
push @set, { question => "刂", complexity => 4, answer => "sword / blade ", description => "かたな", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "katana.wav"   };
push @set, { question => "力", complexity => 3, answer => "strength, power, force, ability ", description => "ちから", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "chikara.wav"   };
push @set, { question => "勹", complexity => 3, answer => "wrap / embrace / wraping enclosure ", description => "ほう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hou.wav"   };
push @set, { question => "匕", complexity => 3, answer => "spoon / katakana 'hi' ", description => "ひ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "hi.wav"   };
push @set, { question => "匚", complexity => 3, answer => "box on side ", description => "ほう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hou.wav"   };
push @set, { question => "匸", complexity => 3, answer => "hiding enclosure radical ", description => "けい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kei.wav"   };
push @set, { question => "十", complexity => 3, answer => "ten ", description => "じゅう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shuu.wav"   };
push @set, { question => "卜", complexity => 4, answer => "divining rod / katakana 'to' ", description => "ぼく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "boku.wav"   };
push @set, { question => "卩", complexity => 4, answer => "seal ", description => "せつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "setsu.wav"   };
push @set, { question => "厂", complexity => 4, answer => "cliff ", description => "かん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kan.wav"   };
push @set, { question => "厶", complexity => 4, answer => "myself / private / katakana 'mu' ", description => "む", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "mu.wav"   };
push @set, { question => "又", complexity => 4, answer => "again ", description => "また", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "mata.wav"   };
push @set, { question => "口", complexity => 4, answer => "mouth / opening / enclosure / box ", description => "くち", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kuchi.wav"   };
push @set, { question => "囗", complexity => 5, answer => "mouth / opening / enclosure / box ", description => "くち", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kuchi.wav"   };
push @set, { question => "土", complexity => 4, answer => "soil, ground ", description => "つち", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tsuchi.wav"   };
push @set, { question => "士", complexity => 4, answer => "gentleman, samurai ", description => "し", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shi.wav"   };
push @set, { question => "夂", complexity => 5, answer => "winter ", description => "ち", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "chi.wav"   };
push @set, { question => "夊", complexity => 5, answer => "winter variant radical ", description => "すい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sui.wav"   };
push @set, { question => "夕", complexity => 5, answer => "evening ", description => "ゆう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "yuu.wav"   };
push @set, { question => "大", complexity => 5, answer => "large / big", description => "おお", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "oo.wav"   };
push @set, { question => "女", complexity => 5, answer => "woman ", description => "じょ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "jo.wav"   };
push @set, { question => "子", complexity => 5, answer => "child", description => "こ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ko.wav"   };
push @set, { question => "宀", complexity => 5, answer => "crown / roof / katakana 'u' ", description => "べん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ben.wav"   };
push @set, { question => "寸", complexity => 5, answer => "measurement, size ", description => "すん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "Sun.wav"   };
push @set, { question => "小", complexity => 6, answer => "small ", description => "しょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shou.wav"   };
push @set, { question => "尢", complexity => 6, answer => "lame / crooked legs / large ", description => "おう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ou.wav"   };
push @set, { question => "尣", complexity => 7, answer => "lame / crooked legs / large ", description => "おう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ou.wav"   };
push @set, { question => "尸", complexity => 6, answer => "corpse / flag ", description => "し", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shi.wav"   };
push @set, { question => "屮", complexity => 6, answer => "left hand / sprout / grass ", description => "てつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tetsu.wav"   };
push @set, { question => "山", complexity => 6, answer => "mountain ", description => "さん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "san.wav"   };
push @set, { question => "巛", complexity => 6, answer => "turning river / curving river ", description => "せん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sen.wav"   };
push @set, { question => "巜", complexity => 7, answer => "turning river / curving river ", description => "せん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sen.wav"   };
push @set, { question => "川", complexity => 6, answer => "river, stream ", description => "かわ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kawa.wav"   };
push @set, { question => "工", complexity => 6, answer => "contruction / craft ", description => "こう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kou.wav"   };
push @set, { question => "己", complexity => 6, answer => "one's self / snake / serpent ", description => "こ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ko.wav"   };
push @set, { question => "巳", complexity => 7, answer => "one's self / snake / serpent ", description => "こ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ko.wav"   };
push @set, { question => "已", complexity => 8, answer => "one's self / snake / serpent ", description => "こ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ko.wav"   };
push @set, { question => "巾", complexity => 6, answer => "napkin / cloth / towel ", description => "きん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kin.wav"   };
push @set, { question => "干", complexity => 7, answer => "dry ", description => "かん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kan.wav"   };
push @set, { question => "幺", complexity => 7, answer => "short / short thread ", description => "よう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "you.wav"   };
push @set, { question => "广", complexity => 7, answer => "dotted cliff / sloping / broad / wide ", description => "げん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "gen.wav"   };
push @set, { question => "廴", complexity => 7, answer => "long stride / stretching ", description => "いん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "in.wav"   };
push @set, { question => "廾", complexity => 7, answer => "twenty / 20 / two hands ", description => "きょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kyou.wav"   };
push @set, { question => "弋", complexity => 7, answer => "ceremony ", description => "よく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "yoku.wav"   };
push @set, { question => "弓", complexity => 8, answer => "bow / archery ", description => "ゆみ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "yumi.wav"   };
push @set, { question => "彐", complexity => 8, answer => "pig's head / pig snout ", description => "けい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kei.wav"   };
push @set, { question => "彑", complexity => 9, answer => "pig's head / pig snout ", description => "けい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kei.wav"   };
push @set, { question => "彡", complexity => 8, answer => "hair / fur / three / 3 ", description => "さん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "san.wav"   };
push @set, { question => "三", complexity => 9, answer => "hair / fur / three / 3 ", description => "さん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "san.wav"   };
push @set, { question => "彳", complexity => 8, answer => "loiter / going man radical ", description => "てき", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "teki.wav"   };
push @set, { question => "心", complexity => 8, answer => "heart ", description => "こころ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kokoro.wav"   };
push @set, { question => "忄", complexity => 9, answer => "heart ", description => "こころ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kokoro.wav"   };
push @set, { question => "戈", complexity => 8, answer => "halberd / arms / festival float", description => "ほこ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hoko.wav"   };
push @set, { question => "戶", complexity => 8, answer => "door ", description => "と", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "to.wav"   };
push @set, { question => "户", complexity => 10, answer => "door ", description => "と", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "to.wav"   };
push @set, { question => "戸", complexity => 11, answer => "door ", description => "と", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "to.wav"   };
push @set, { question => "手", complexity => 8, answer => "hand ", description => "て", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "te.wav"   };
push @set, { question => "扌", complexity => 10, answer => "hand ", description => "て", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "te.wav"   };
push @set, { question => "支", complexity => 9, answer => "branch / support ", description => "し", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shi.wav"   };
push @set, { question => "攴", complexity => 9, answer => "folding chair / strike / hit ", description => "ぶん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "bun.wav"   };
push @set, { question => "攵", complexity => 10, answer => "folding chair / strike / hit ", description => "ぶん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "bun.wav"   };
push @set, { question => "斗", complexity => 9, answer => "sake dipper ", description => "と", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "to.wav"   };
push @set, { question => "斤", complexity => 9, answer => "loaf counter / axe radical ", description => "おの", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ono.wav"   };
push @set, { question => "方", complexity => 9, answer => "direction / person / way of doing ", description => "~かた", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kata.wav"   };
push @set, { question => "无", complexity => 9, answer => "nothing / non-existant / not ", description => "ぶ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "bu.wav"   };
push @set, { question => "旡", complexity => 10, answer => "nothing / non-existant / not ", description => "ぶ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "bu.wav"   };
push @set, { question => "日", complexity => 10, answer => "sun / day ", description => "にち", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "nichi.wav"   };
push @set, { question => "曰", complexity => 10, answer => "history / pretext / say ", description => "えつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "etsu.wav"   };
push @set, { question => "月", complexity => 10, answer => "moon / month / bodily organ radical ", description => "つき", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tsuki.wav"   };
push @set, { question => "木", complexity => 10, answer => "tree / wood ", description => "もく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "moku.wav"   };
push @set, { question => "欠", complexity => 11, answer => "lack / deficiency / yawn radical ", description => "あくび", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "akubi.wav"   };
push @set, { question => "止", complexity => 11, answer => "stop ", description => "と", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "to.wav"   };
push @set, { question => "歹", complexity => 11, answer => "death / decay ", description => "がつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "gatsu.wav"   };
push @set, { question => "歺", complexity => 12, answer => "death / decay ", description => "がつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "gatsu.wav"   };
push @set, { question => "殳", complexity => 11, answer => "windy-again radical ", description => "しゅ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shu.wav"   };
push @set, { question => "毋", complexity => 11, answer => "mother ", description => "ぼ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "bo.wav"   };
push @set, { question => "母", complexity => 12, answer => "mother ", description => "ぼ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "bo.wav"   };
push @set, { question => "比", complexity => 11, answer => "compare / race / ratio / Phillipines", description => "ひ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "hi.wav"   };
push @set, { question => "毛", complexity => 11, answer => "fur / hair / feather / down ", description => "け", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ke.wav"   };
push @set, { question => "氏", complexity => 11, answer => "family name / surname / clan ", description => "うじ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "uji.wav"   };
push @set, { question => "气", complexity => 12, answer => "spirit / steam / breath ", description => "きがまえ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kigamae.wav"   };
push @set, { question => "水", complexity => 12, answer => "water ", description => "すい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sui.wav"   };
push @set, { question => "氵", complexity => 13, answer => "water ", description => "すい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sui.wav"   };
push @set, { question => "氺", complexity => 14, answer => "water ", description => "すい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sui.wav"   };
push @set, { question => "火", complexity => 12, answer => "fire ", description => "ひ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "hi.wav"   };
push @set, { question => "灬", complexity => 13, answer => "fire ", description => "ひ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "hi.wav"   };
push @set, { question => "爪", complexity => 12, answer => "claw / nail / talon ", description => "つめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tsume.wav"   };
push @set, { question => "爫", complexity => 13, answer => "claw / nail / talon ", description => "つめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tsume.wav"   };
push @set, { question => "父", complexity => 12, answer => "father ", description => "ちち", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "chichi.wav"   };
push @set, { question => "爻", complexity => 12, answer => "mix / associate with / double 'X' radical ", description => "こう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kou.wav"   };
push @set, { question => "爿", complexity => 12, answer => "split wood / piece of wood ", description => "しょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shou.wav"   };
push @set, { question => "片", complexity => 13, answer => "slice / sheet / side / kata radical ", description => "かた", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kata.wav"   };
push @set, { question => "牙", complexity => 13, answer => "tusk / fang ", description => "が", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ga.wav"   };
push @set, { question => "牛", complexity => 13, answer => "cow / cattle / ox ", description => "うし", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ushi.wav"   };
push @set, { question => "牜", complexity => 14, answer => "cow / cattle / ox ", description => "うし", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ushi.wav"   };
push @set, { question => "犬", complexity => 13, answer => "dog ", description => "いぬ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "inu.wav"   };
push @set, { question => "犭", complexity => 14, answer => "dog ", description => "いぬ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "inu.wav"   };
push @set, { question => "玄", complexity => 13, answer => "occult / mysterious / dark ", description => "げん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "gen.wav"   };
push @set, { question => "玉", complexity => 13, answer => "gem / stone / jewell / ball / jade ", description => "たま", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tama.wav"   };
push @set, { question => "王", complexity => 14, answer => "king, monarch ", description => "おう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ou.wav"   };
push @set, { question => "瓜", complexity => 14, answer => "melon ", description => "うり", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "uri.wav"   };
push @set, { question => "瓦", complexity => 14, answer => "tile ", description => "かわら", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kawara.wav"   };
push @set, { question => "甘", complexity => 14, answer => "sweet ", description => "あま", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ama.wav"   };
push @set, { question => "生", complexity => 14, answer => "life ", description => "せい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sei.wav"   };
push @set, { question => "用", complexity => 14, answer => "use / purpose ", description => "よう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "you.wav"   };
push @set, { question => "田", complexity => 15, answer => "rice field, rice paddy ", description => "た", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ta.wav"   };
push @set, { question => "疋", complexity => 15, answer => "head (of cattle) ", description => "ひき", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hiki.wav"   };
push @set, { question => "疒", complexity => 15, answer => "sickness / disease ", description => "だく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "daku.wav"   };
push @set, { question => "癶", complexity => 15, answer => "dotted tent radical ", description => "はつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hatsu.wav"   };
push @set, { question => "白", complexity => 15, answer => "white / blank ", description => "しろ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shiro.wav"   };
push @set, { question => "皮", complexity => 15, answer => "skin, hide ", description => "かわ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kawa.wav"   };
push @set, { question => "皿", complexity => 15, answer => "plate, counter for plates or helpings ", description => "さら", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sara.wav"   };
push @set, { question => "目", complexity => 15, answer => "eye / eyeball / eyesight ", description => "もく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "moku.wav"   };
push @set, { question => "矛", complexity => 16, answer => "halberd / arms / festival car / float ", description => "ほこ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hoko.wav"   };
push @set, { question => "矢", complexity => 16, answer => "dart / arrow ", description => "や", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ya.wav"   };
push @set, { question => "石", complexity => 16, answer => "stone, small rock ", description => "いし", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ishi.wav"   };
push @set, { question => "示", complexity => 16, answer => "indicate / point out ", description => "しめす", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shimesu.wav"   };
push @set, { question => "礻", complexity => 17, answer => "indicate / point out ", description => "しめす", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shimesu.wav"   };
push @set, { question => "禸", complexity => 16, answer => "track / gun / legs / rump ", description => "じゅう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shuu.wav"   };
push @set, { question => "禾", complexity => 16, answer => "two branch tree ", description => "か", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ka.wav"   };
push @set, { question => "穴", complexity => 16, answer => "hole / cavity / cave ", description => "あな", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ana.wav"   };
push @set, { question => "立", complexity => 16, answer => "standing ", description => "た", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ta.wav"   };
push @set, { question => "竹", complexity => 16, answer => "bamboo ", description => "たけ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "take.wav"   };
push @set, { question => "米", complexity => 17, answer => "uncooked rice / America ", description => "こめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kome.wav"   };
push @set, { question => "糸", complexity => 17, answer => "thread, yarn ", description => "いと", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ito.wav"   };
push @set, { question => "糹", complexity => 18, answer => "thread, yarn ", description => "いと", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ito.wav"   };
push @set, { question => "缶", complexity => 17, answer => "can / jar / tin ", description => "かん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kan.wav"   };
push @set, { question => "网", complexity => 17, answer => "net / mesh ", description => "あみめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "amime.wav"   };
push @set, { question => "罒", complexity => 18, answer => "net / mesh ", description => "あみめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "amime.wav"   };
push @set, { question => "罓", complexity => 19, answer => "net / mesh ", description => "あみめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "amime.wav"   };
push @set, { question => "羊", complexity => 17, answer => "sheep ", description => "よう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "you.wav"   };
push @set, { question => "羽", complexity => 19, answer => "feather / wing / bird counter ", description => "は", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ha.wav"   };
push @set, { question => "老", complexity => 17, answer => "old / old age / growing old ", description => "おいる", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "oiru.wav"   };
push @set, { question => "考", complexity => 18, answer => "old / old age / growing old ", description => "おいる", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "oiru.wav"   };
push @set, { question => "而", complexity => 17, answer => "rake ", description => "じ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ji.wav"   };
push @set, { question => "耒", complexity => 17, answer => "plow / 3 branch tree ", description => "らい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "rai.wav"   };
push @set, { question => "耳", complexity => 18, answer => "ear / hearing ", description => "みみ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "mimi.wav"   };
push @set, { question => "聿", complexity => 18, answer => "writing brush ", description => "ふで", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hude.wav"   };
push @set, { question => "肉", complexity => 18, answer => "meat ", description => "にく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "niku.wav"   };
push @set, { question => "臣", complexity => 18, answer => "retainer / subject ", description => "しん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shin.wav"   };
push @set, { question => "自", complexity => 18, answer => "oneself ", description => "じ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ji.wav"   };
push @set, { question => "至", complexity => 18, answer => "reach / achieve / climax ", description => "いたる", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "itaru.wav"   };
push @set, { question => "臼", complexity => 19, answer => "mortar ", description => "うす", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "usu.wav"   };
push @set, { question => "舌", complexity => 19, answer => "tongue ", description => "した", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shita.wav"   };
push @set, { question => "舛", complexity => 19, answer => "dancing radical ", description => "せん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sen.wav"   };
push @set, { question => "舟", complexity => 19, answer => "boat / ship / vessel ", description => "しゅう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shuu.wav"   };
push @set, { question => "艮", complexity => 19, answer => "stopping /good radical ", description => "こん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kon.wav"   };
push @set, { question => "色", complexity => 19, answer => "color ", description => "いろ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "iro.wav"   };
push @set, { question => "艸", complexity => 19, answer => "grass ", description => "くさ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kusa.wav"   };
push @set, { question => "艹", complexity => 20, answer => "grass ", description => "くさ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kusa.wav"   };
push @set, { question => "虍", complexity => 20, answer => "tiger / tiger stripes ", description => "こ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ko.wav"   };
push @set, { question => "虫", complexity => 20, answer => "insect / worm ", description => "むし", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "mushi.wav"   };
push @set, { question => "血", complexity => 20, answer => "blood ", description => "ち", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "chi.wav"   };
push @set, { question => "行", complexity => 20, answer => "go / to go ", description => "い", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "i.wav"   };
push @set, { question => "衣", complexity => 20, answer => "clothes / garment / dressing ", description => "い", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "i.wav"   };
push @set, { question => "衤", complexity => 21, answer => "clothes / garment / dressing ", description => "い", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "i.wav"   };
push @set, { question => "西", complexity => 20, answer => "west ", description => "にし", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "nishi.wav"   };
push @set, { question => "襾", complexity => 21, answer => "west ", description => "にし", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "nishi.wav"   };
push @set, { question => "見", complexity => 22, answer => "see / look / show ", description => "み", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "mi.wav"   };
push @set, { question => "角", complexity => 22, answer => "angle / corner / square ", description => "かど", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kado.wav"   };
push @set, { question => "言", complexity => 21, answer => "to say / speech ", description => "げん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "gen.wav"   };
push @set, { question => "訁", complexity => 22, answer => "to say / speech ", description => "げん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "gen.wav"   };
push @set, { question => "谷", complexity => 21, answer => "valley, ravine ", description => "たに", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tani.wav"   };
push @set, { question => "豆", complexity => 21, answer => "beans / pea / midget", description => "まめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "mame.wav"   };
push @set, { question => "豕", complexity => 21, answer => "pig / hog / boar ", description => "し", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shi.wav"   };
push @set, { question => "豸", complexity => 21, answer => "badger / snake / legless insect ", description => "ち", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "chi.wav"   };
push @set, { question => "貝", complexity => 21, answer => "shellfish / shell ", description => "ばい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "bai.wav"   };
push @set, { question => "赤", complexity => 21, answer => "red / crimson ", description => "せき", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "seki.wav"   };
push @set, { question => "走", complexity => 22, answer => "run ", description => "そう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sou.wav"   };
push @set, { question => "赱", complexity => 23, answer => "run ", description => "そう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sou.wav"   };
push @set, { question => "足", complexity => 22, answer => "leg / foot ", description => "あし", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ashi.wav"   };
push @set, { question => "身", complexity => 22, answer => "person / one's station in life ", description => "しん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shin.wav"   };
push @set, { question => "車", complexity => 22, answer => "car ", description => "くるま", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kuruma.wav"   };
push @set, { question => "辛", complexity => 22, answer => "spicy / bitter / hot ", description => "から", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kara.wav"   };
push @set, { question => "辰", complexity => 22, answer => "dragon ", description => "たつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tatsu.wav"   };
push @set, { question => "辵", complexity => 22, answer => "walk / road radical ", description => "ちゃく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "chaku.wav"   };
push @set, { question => "辶", complexity => 23, answer => "walk / road radical ", description => "ちゃく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "chaku.wav"   };
push @set, { question => "邑", complexity => 22, answer => "village / rural community ", description => "ゆう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "yuu.wav"   };
push @set, { question => "阝", complexity => 23, answer => "village / rural community ", description => "ゆう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "yuu.wav"   };
push @set, { question => "酉", complexity => 23, answer => "west / bird / sake radical ", description => "ゆう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "yuu.wav"   };
push @set, { question => "釆", complexity => 23, answer => "separate / divide / topped rice radical ", description => "はん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "han.wav"   };
push @set, { question => "里", complexity => 23, answer => "village / parent's home ", description => "さと", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sato.wav"   };
push @set, { question => "金", complexity => 23, answer => "money, gold ", description => "かね", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kane.wav"   };
push @set, { question => "釒", complexity => 24, answer => "money, gold ", description => "かね", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kane.wav"   };
push @set, { question => "長", complexity => 23, answer => "long, leader ", description => "ちょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "chou.wav"   };
push @set, { question => "镸", complexity => 24, answer => "long, leader ", description => "ちょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "chou.wav"   };
push @set, { question => "門", complexity => 23, answer => "gate ", description => "もん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "mon.wav"   };
push @set, { question => "阜", complexity => 24, answer => "hill / mound ", description => "ふう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "huu.wav"   };
push @set, { question => "阝", complexity => 25, answer => "hill / mound ", description => "ふう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "huu.wav"   };
push @set, { question => "隶", complexity => 24, answer => "extend / slave radical ", description => "たい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tai.wav"   };
push @set, { question => "隹", complexity => 24, answer => "old bird radical ", description => "さい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sai.wav"   };
push @set, { question => "雨", complexity => 24, answer => "rain ", description => "あめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ame.wav"   };
push @set, { question => "青", complexity => 24, answer => "blue / green / green light ", description => "あお", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ao.wav"   };
push @set, { question => "靑", complexity => 25, answer => "blue / green / green light ", description => "あお", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ao.wav"   };
push @set, { question => "非", complexity => 24, answer => "wrong / mistake ", description => "ひ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "hi.wav"   };
push @set, { question => "面", complexity => 24, answer => "mask / face / surface ", description => "めん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "men.wav"   };
push @set, { question => "靣", complexity => 25, answer => "mask / face / surface ", description => "めん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "men.wav"   };
push @set, { question => "革", complexity => 25, answer => "leather / pelt / become serious ", description => "かぐ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kagu.wav"   };
push @set, { question => "韋", complexity => 25, answer => "tanned leather radical ", description => "そむく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "somuku.wav"   };
push @set, { question => "韭", complexity => 25, answer => "leek radical ", description => "きょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kyou.wav"   };
push @set, { question => "音", complexity => 25, answer => "sound / noise ", description => "おと", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "oto.wav"   };
push @set, { question => "頁", complexity => 25, answer => "page / leaf ", description => "けつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ketsu.wav"   };
push @set, { question => "風", complexity => 25, answer => "wind / air / manner ", description => "ふう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "huu.wav"   };
push @set, { question => "飛", complexity => 26, answer => "fly / skip over / scatter ", description => "ひ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "hi.wav"   };
push @set, { question => "食", complexity => 26, answer => "food / eat ", description => "しょく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shoku.wav"   };
push @set, { question => "飠", complexity => 27, answer => "food / eat ", description => "しょく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shoku.wav"   };
push @set, { question => "首", complexity => 26, answer => "neck / song counter ", description => "しゅ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shu.wav"   };
push @set, { question => "香", complexity => 26, answer => "incense / smell / perfume ", description => "こう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kou.wav"   };
push @set, { question => "馬", complexity => 26, answer => "horse ", description => "ば", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ba.wav"   };
push @set, { question => "骨", complexity => 26, answer => "bone / skeleton ", description => "こつ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kotsu.wav"   };
push @set, { question => "高", complexity => 26, answer => "tall / high / expensive ", description => "こう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kou.wav"   };
push @set, { question => "髙", complexity => 27, answer => "tall / high / expensive ", description => "こう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kou.wav"   };
push @set, { question => "髟", complexity => 26, answer => "long hair radical ", description => "ひょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "hyou.wav"   };
push @set, { question => "鬥", complexity => 26, answer => "fighting radical / broken gate radical ", description => "とう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tou.wav"   };
push @set, { question => "鬯", complexity => 27, answer => "fragrant herbs ", description => "ちょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "chou.wav"   };
push @set, { question => "鬲", complexity => 27, answer => "tripod / three legged pot ", description => "かく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kaku.wav"   };
push @set, { question => "鬼", complexity => 27, answer => "ghost / demon / ogre / devil ", description => "き", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ki.wav"   };
push @set, { question => "魚", complexity => 27, answer => "fish ", description => "ぎょ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "kyo.wav"   };
push @set, { question => "鳥", complexity => 27, answer => "bird / chicken ", description => "ちょう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "chou.wav"   };
push @set, { question => "鹵", complexity => 27, answer => "salt ", description => "ろ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ro.wav"   };
push @set, { question => "鹿", complexity => 27, answer => "deer ", description => "しか", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "shika.wav"   };
push @set, { question => "麥", complexity => 28, answer => "wheat radical ", description => "ばく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "baku.wav"   };
push @set, { question => "麻", complexity => 28, answer => "hemp / flax ", description => "ま", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ma.wav"   };
push @set, { question => "黄", complexity => 28, answer => "yellow ", description => "おう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ou.wav"   };
push @set, { question => "黍", complexity => 28, answer => "millet ", description => "きび", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kibi.wav"   };
push @set, { question => "黒", complexity => 28, answer => "black ", description => "くろ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kuro.wav"   };
push @set, { question => "黹", complexity => 29, answer => "sewing radical ", description => "ち", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "chi.wav"   };
push @set, { question => "黽", complexity => 28, answer => "frog / amphibian / industry ", description => "ぼう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "bou.wav"   };
push @set, { question => "黾", complexity => 29, answer => "frog / amphibian / industry ", description => "ぼう", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "bou.wav"   };
push @set, { question => "鼎", complexity => 29, answer => "three legged pot / tripod ", description => "てい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "tei.wav"   };
push @set, { question => "鼓", complexity => 29, answer => "drum / beat ", description => "こ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "ko.wav"   };
push @set, { question => "鼠", complexity => 29, answer => "rat / mouse / dark grey ", description => "そ", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "so.wav"   };
push @set, { question => "齊", complexity => 29, answer => "alike / even / uniform / same ", description => "せい", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "sei.wav"   };
push @set, { question => "齒", complexity => 28, answer => "tooth / molar / cog ", description => "し", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shi.wav"   };
push @set, { question => "歯", complexity => 29, answer => "tooth / molar / cog ", description => "し", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shi.wav"   };
push @set, { question => "齿", complexity => 30, answer => "tooth / molar / cog ", description => "し", question_type => "text", answer_type => "multi", audiobank => $ab2, audio_file => "shi.wav"   };
push @set, { question => "龍", complexity => 28, answer => "dragon / imperial ", description => "りゅう ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ryuu.wav"   };
push @set, { question => "竜", complexity => 29, answer => "dragon / imperial ", description => "りゅう ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "ryuu.wav"   };
push @set, { question => "龜", complexity => 28, answer => "turtle, tortoise ", description => "かめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kame.wav"   };
push @set, { question => "亀", complexity => 29, answer => "turtle, tortoise ", description => "かめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kame.wav"   };
push @set, { question => "龟", complexity => 30, answer => "turtle, tortoise ", description => "かめ", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "kame.wav"   };
push @set, { question => "龠", complexity => 30, answer => "flute ", description => "やく", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "yaku.wav"   };
push @set, { question => "文", complexity => 30, answer => "sentence ", description => "ぶん", question_type => "text", answer_type => "multi", audiobank => $ab, audio_file => "bun.wav"   };



sub get_set {
    return @set;
}

1; # End of Quiz::Flashcards::Sets::Kanji_Radicals::English
