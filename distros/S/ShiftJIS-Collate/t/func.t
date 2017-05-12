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
 [qw/ ‚¢‚Ê ƒLƒcƒl ‚³‚é ‚½‚Ê‚« ƒlƒR ‚Ë‚¸‚Ý ƒpƒ“ƒ_ ‚Ð‚å‚¤ ƒ‰ƒCƒIƒ“ /],
 [qw/ ƒf[ƒ^ ƒfƒFƒ^ ƒfƒGƒ^ ƒf[ƒ^[ ƒf[ƒ^ƒ@ ƒf[ƒ^ƒA
   ƒfƒFƒ^[ ƒfƒFƒ^ƒ@ ƒfƒFƒ^ƒA ƒfƒGƒ^[ ƒfƒGƒ^ƒ@ ƒfƒGƒ^ƒA /],
 [qw/ ‚³‚Æ ‚³‚Ç ‚³‚Æ‚¤ ‚³‚Ç‚¤ ‚³‚Æ‚¤‚â ƒTƒg[ ‚³‚Æ‚¨‚â /],
 [qw/ ƒtƒ@[ƒ‹ ‚Ô‚ ‚¢ ƒtƒ@ƒDƒ‹ ƒtƒ@ƒEƒ‹ ƒtƒ@ƒ“ ‚Ó‚ ‚ñ ƒtƒAƒ“ ‚Ô‚ ‚ñ /],
 [qw/ ‚µ‚å‚¤ ‚µ‚æ‚¤ ‚¶‚å‚¤ ‚¶‚æ‚¤ ‚µ‚å‚¤‚µ ‚µ‚å‚¤‚¶ ‚µ‚æ‚¤‚¶
      ‚¶‚å‚¤‚µ ‚¶‚å‚¤‚¶ ƒVƒ‡[ ƒVƒ‡ƒI ƒWƒ‡[ ‚¶‚å‚¨‚¤ ƒWƒ‡[ƒW /],
 [qw/‚·‚· ‚·‚¸ ‚·T‚« ‚·‚·‚« ‚·„©U‚« ‚·‚¸‚« ‚·‚¸‚± /],
);

$s = 0;
for(@data){
  my %h;
  @h{ @$_ } =();
  $s ++ unless join(":", @$_) eq join(":", $Collator->sort(keys %h));
}
print ! $s ? "ok" : "not ok", " 2\n";

print $Collator->cmp("Perl", "‚o‚…‚’‚Œ") == 0
   && $mod->new( level => 4 )->cmp("Perl", "‚o‚…‚’‚Œ") == 0
   && $mod->new( level => 5 )->cmp("Perl", "‚o‚…‚’‚Œ") == -1
    ? "ok" : "not ok", " 3\n";

print $Collator->cmp("PERL", "‚o‚…‚’‚Œ") == 1
   && $mod->new( level => 3 )->cmp("PERL", "‚o‚…‚’‚Œ") == 1
   && $mod->new( level => 2 )->cmp("PERL", "‚o‚…‚’‚Œ") == 0
    ? "ok" : "not ok", " 4\n";

print $Collator->cmp("Perl", "‚o‚d‚q‚k") == -1
   && $mod->new( level => 3 )->cmp("Perl", "‚o‚d‚q‚k") == -1
   && $mod->new( level => 2 )->cmp("Perl", "‚o‚d‚q‚k") == 0
    ? "ok" : "not ok", " 5\n";

print $Collator->cmp("‚ ‚¢‚¤‚¦‚¨", "ƒAƒCƒEƒGƒI") == -1
    ? "ok" : "not ok", " 6\n";

print $mod->new( level => 3 )->cmp("‚ ‚¢‚¤‚¦‚¨", "ƒAƒCƒEƒGƒI") == 0
   && $mod->new( katakana_before_hiragana => 1 )
          ->cmp("‚ ‚¢‚¤‚¦‚¨", "ƒAƒCƒEƒGƒI") == 1
   && $mod->new( katakana_before_hiragana => 1,
            level => 3 )->cmp("‚ ‚¢‚¤‚¦‚¨", "ƒAƒCƒEƒGƒI") == 0
    ? "ok" : "not ok", " 7\n";

print $Collator->cmp("perl", "PERL") == -1
   && $mod->new( level => 2 )->cmp("perl", "PERL") == 0
    ? "ok" : "not ok", " 8\n";

print $mod->new(upper_before_lower => 1)->cmp("perl", "PERL") == 1
    ? "ok" : "not ok", " 9\n";

print $mod->new(upper_before_lower => 1, level => 2)->cmp("perl", "PERL") == 0
    ? "ok" : "not ok", " 10\n";

print $Collator->cmp("±²³´µ", "ƒAƒCƒEƒGƒI") == 0
    ? "ok" : "not ok", " 11\n";

print $mod->new( level => 5 )->cmp("±²³´µ", "ƒAƒCƒEƒGƒI") == 1
    ? "ok" : "not ok", " 12\n";

print $Collator->cmp("XYZ", "abc") == 1
    ? "ok" : "not ok", " 13\n";

print $mod->new( level => 1 )->cmp("XYZ", "abc") == 1
    ? "ok" : "not ok", " 14\n";

print $Collator->cmp("XYZ", "ABC") == 1
   && $Collator->cmp("xyz", "ABC") == 1
    ? "ok" : "not ok", " 15\n";

print $Collator->gt("‚ ‚ ", "‚ T")
   && $Collator->ge("‚ ‚ ", "‚ T")
   && $Collator->ne("‚ ‚ ", "‚ T")
    ? "ok" : "not ok", " 16\n";

print $mod->new( level => 3 )->gt("‚ ‚ ", "‚ T")
   && $mod->new( level => 3 )->ge("‚ ‚ ", "‚ T")
   && $mod->new( level => 3 )->ne("‚ ‚ ", "‚ T")
   && $mod->new( level => 3 )->lt("‚ ‚Ÿ", "‚ T")
   && $mod->new( level => 3 )->le("‚ ‚Ÿ", "‚ T")
   && $mod->new( level => 3 )->ne("‚ ‚Ÿ", "‚ T")
    ? "ok" : "not ok", " 17\n";

print $mod->new( level => 2 )->eq("‚ ‚ ", "‚ T")
   && $mod->new( level => 2 )->ge("‚ ‚ ", "‚ T")
   && $mod->new( level => 2 )->le("‚ ‚ ", "‚ T")
   && $mod->new( level => 1 )->lt("‚ ‚ ", "‚ U")
   && $mod->new( level => 1 )->le("‚ ‚ ", "‚ U")
   && $mod->new( level => 1 )->ne("‚ ‚ ", "‚ U")
    ? "ok" : "not ok", " 18\n";

print $mod->new( level => 2 )->gt("‚½‚¾", "‚½T")
   && $mod->new( level => 2 )->ge("‚½‚¾", "‚½T")
   && $mod->new( level => 2 )->ne("‚½‚¾", "‚½T")
   && $mod->new( level => 2 )->eq("‚½‚¾", "‚½U")
   && $mod->new( level => 2 )->ge("‚½‚¾", "‚½U")
   && $mod->new( level => 2 )->le("‚½‚¾", "‚½U")
    ? "ok" : "not ok", " 19\n";

print $mod->new( level => 1 )->eq("‚½‚¾", "‚½T")
   && $mod->new( level => 1 )->ge("‚½‚¾", "‚½T")
   && $mod->new( level => 1 )->le("‚½‚¾", "‚½T")
    ? "ok" : "not ok", " 20\n";

print $Collator->cmp("ƒpƒAƒ‹", "ƒp[ƒ‹") == 1
    ? "ok" : "not ok", " 21\n";

print $mod->new( level => 3 )->cmp("ƒpƒAƒ‹", "ƒp[ƒ‹") == 1
   && $mod->new( level => 3 )->cmp("ƒpƒ@ƒ‹", "ƒp[ƒ‹") == 1
   && $mod->new( level => 2 )->cmp("ƒpƒAƒ‹", "ƒp[ƒ‹") == 0
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

print $Collator->cmp('‚`', 'ˆŸ') == -1
    ? "ok" : "not ok", " 26\n";

print $mod->new( level => 1, kanji => 1 )->cmp('‚`', 'ˆŸ') == 1
   && $mod->new( level => 1, kanji => 1 )->cmp('‚`', 'W') == -1
   && $mod->new( level => 1, kanji => 1 )->cmp('W', 'ˆŸ') == 1
   && $mod->new( level => 1, kanji => 2 )->cmp('‚`', 'ˆŸ') == -1
   && $mod->new( level => 1, kanji => 2 )->cmp('‚`', 'W') == -1
   && $mod->new( level => 1, kanji => 2 )->cmp('W', 'ˆŸ') == -1
   && $mod->new( level => 1, kanji => 0 )->cmp('ˆŸ', 'ˆê') == -1
   && $mod->new( level => 1, kanji => 1 )->cmp('ˆŸ', 'ˆê') == 0
   && $mod->new( level => 1, kanji => 2 )->cmp('ˆŸ', 'ˆê') == -1
    ? "ok" : "not ok", " 27\n";

print $Collator->cmp('¬', 'ê¤') == 1
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

  $sorted  = 'ƒpƒCƒiƒbƒvƒ‹ ƒnƒbƒg ‚Í‚È ƒo[ƒi[ ƒoƒiƒi ƒp[ƒ‹ ƒpƒƒfƒB';
  @subject = qw(ƒpƒƒfƒB ƒpƒCƒiƒbƒvƒ‹ ƒoƒiƒi ƒnƒbƒg ‚Í‚È ƒp[ƒ‹ ƒo[ƒi[);

  print
      $sorted eq join(' ', $ignore_prolong->sort(@subject))
   && $sorted eq join(' ', $delete_prolong->sort(@subject))
   && $level2->cmp("ƒpƒAƒ‹", "ƒp[ƒ‹") == 0
   && $level3->cmp("ƒpƒAƒ‹", "ƒp[ƒ‹") == 1
   && $level3->cmp("ƒpƒ@ƒ‹", "ƒp[ƒ‹") == 1
   && $level4->cmp("Êß°Ù",   "ƒp[ƒ‹") == 0
   && $level5->cmp("ƒp[ƒ‹", "Êß°Ù",4) == -1
   && $level2->cmp("ƒpƒp", "‚Ï‚Ï") == 0
   && $jis->cmp("ƒpƒp", "‚Ï‚Ï") == 1
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
   && $mod->new( level => 3 )->gt('ƒnƒnƒnƒn', 'ƒnRRR')
   && $mod->new( level => 2 )->eq('ƒnƒnƒnƒn', 'ƒnRRR')
   && $mod->new( level => 3 )->gt('ƒLƒCƒCƒC', 'ƒL[[[')
   && $mod->new( level => 2 )->eq('ƒLƒCƒCƒC', 'ƒL[[[')
    ? "ok" : "not ok", " 33\n";

##########

my (@source, $result);

@source = (
  ['‰i“c', '‚È‚ª‚½'],
  ['¬ŽR', '‚¨‚â‚Ü'],
  ['’·“c', '‚¨‚³‚¾'],
  ['’·“c', '‚È‚ª‚½'],
  ['¬ŽR', '‚±‚â‚Ü'],
);

$result = join ';', map join(',', @$_), $Collator->sortYomi(@source);

print $result eq
  '’·“c,‚¨‚³‚¾;¬ŽR,‚¨‚â‚Ü;¬ŽR,‚±‚â‚Ü;‰i“c,‚È‚ª‚½;’·“c,‚È‚ª‚½'
? "ok" : "not ok", " 34\n";

@source = (
  ['àV“‡',   '‚³‚í‚µ‚Ü'],
  ['‚S–Ê‘Ì', '‚µ‚ß‚ñ‚½‚¢'],
  ['‰Í“c',   '‚©‚í‚¾'],
  ['“yˆä',   '‚Â‚¿‚¢'],
  ['ƒ¿•ö‰ó', 'ƒAƒ‹ƒtƒ@‚Ù‚¤‚©‚¢'],
  ['ƒ¡ŠÖ”', 'ƒKƒ“ƒ}‚©‚ñ‚·‚¤'],
  ['Perl',   'ƒp[ƒ‹'],
  ['‚SŽŸŒ³', '‚æ‚¶‚°‚ñ'],
  ['ƒÀü',   'ƒx[ƒ^‚¹‚ñ'],
  ['Šp“c',   '‚©‚­‚½'],
  ['‘ò“‡',   '‚³‚í‚µ‚Ü'],
  ['‰Í“à',   '‚©‚í‚¿'],
  ['‘ò“c',   '‚³‚í‚¾'],
  ['‰Í“à',   '‚±‚¤‚¿'],
  ['‚QF«', '‚É‚µ‚å‚­‚¹‚¢'],
  ['àV“c',   '‚³‚í‚¾'],
  ['“yˆä',   '‚Ç‚¢'],
  ['‚p’l',   'ƒLƒ…[‚¿'],
  ['‰Í¼',   '‚©‚³‚¢'],
  ['àV“ˆ',   '‚³‚í‚µ‚Ü'],
  ['‚i‚h‚r', '‚¶‚·'],
  ['ŠÖ“Œ',   '‚©‚ñ‚Æ‚¤'],
  ['‰Í•Ó',   '‚©‚í‚×'],
  ['‘ò“ˆ',   '‚³‚í‚µ‚Ü'],
  ['Šp“c',   '‚©‚Ç‚½'],
  ['“y‹',   '‚Â‚¿‚¢'],
  ['‚U–Ê‘Ì', '‚ë‚­‚ß‚ñ‚½‚¢'],
  ['Šp“c',   '‚Â‚Ì‚¾'],
  ['“y‹',   '‚Ç‚¢'],
  ['‰Í‡',   '‚©‚í‚¢'],
);

$result = join ';', map join(',', @$_), $Collator->sortDaihyo(@source);

print $result eq
  '‚S–Ê‘Ì,‚µ‚ß‚ñ‚½‚¢;‚QF«,‚É‚µ‚å‚­‚¹‚¢;‚SŽŸŒ³,‚æ‚¶‚°‚ñ;' .
  '‚U–Ê‘Ì,‚ë‚­‚ß‚ñ‚½‚¢;ƒ¿•ö‰ó,ƒAƒ‹ƒtƒ@‚Ù‚¤‚©‚¢;ƒ¡ŠÖ”,ƒKƒ“ƒ}‚©‚ñ‚·‚¤;' .
  'ƒÀü,ƒx[ƒ^‚¹‚ñ;‚p’l,ƒLƒ…[‚¿;‚i‚h‚r,‚¶‚·;Perl,ƒp[ƒ‹;‰Í¼,‚©‚³‚¢;' .
  '‰Í‡,‚©‚í‚¢;‰Í“c,‚©‚í‚¾;‰Í“à,‚©‚í‚¿;‰Í•Ó,‚©‚í‚×;Šp“c,‚©‚­‚½;' .
  'Šp“c,‚©‚Ç‚½;ŠÖ“Œ,‚©‚ñ‚Æ‚¤;‰Í“à,‚±‚¤‚¿;‘ò“‡,‚³‚í‚µ‚Ü;‘ò“ˆ,‚³‚í‚µ‚Ü;' .
  '‘ò“c,‚³‚í‚¾;àV“‡,‚³‚í‚µ‚Ü;àV“ˆ,‚³‚í‚µ‚Ü;àV“c,‚³‚í‚¾;Šp“c,‚Â‚Ì‚¾;' .
  '“yˆä,‚Â‚¿‚¢;“y‹,‚Â‚¿‚¢;“yˆä,‚Ç‚¢;“y‹,‚Ç‚¢'
? "ok" : "not ok", " 35\n";


sub toU {
    my $char = shift;
    return $char eq 'ˆê' ? 0x4E00 :
	   $char eq 'ˆŸ' ? 0x4E9C : 0x9999;
}

print $Collator->lt('‚`', 'ˆŸ')
    ? "ok" : "not ok", " 36\n";

print $mod->new( level => 1, kanji => 1 )->gt('‚`', 'ˆŸ')
   && $mod->new( level => 1, kanji => 1 )->lt('‚`', 'W')
   && $mod->new( level => 1, kanji => 1 )->gt('W', 'ˆŸ')
   && $mod->new( level => 1, kanji => 1 )->eq('ˆŸ', 'ˆê')
    ? "ok" : "not ok", " 37\n";

print $mod->new( level => 1, kanji => 0 )->lt('ˆŸ', 'ˆê')
   && $mod->new( level => 1, kanji => 2 )->lt('‚`', 'ˆŸ')
   && $mod->new( level => 1, kanji => 2 )->lt('‚`', 'W')
   && $mod->new( level => 1, kanji => 2 )->lt('W', 'ˆŸ')
   && $mod->new( level => 1, kanji => 2 )->lt('ˆŸ', 'ˆê')
    ? "ok" : "not ok", " 38\n";

print $mod->new( level => 1, kanji => 3, tounicode => \&toU )->lt('‚`', 'ˆŸ')
   && $mod->new( level => 1, kanji => 3, tounicode => \&toU )->lt('‚`', 'W')
   && $mod->new( level => 1, kanji => 3, tounicode => \&toU )->lt('W', 'ˆŸ')
   && $mod->new( level => 1, kanji => 3, tounicode => \&toU )->gt('ˆŸ', 'ˆê')
    ? "ok" : "not ok", " 39\n";

print $Collator->lt('„ª', '@') ? "ok" : "not ok", " 40\n";
print $Collator->lt('@', 'V') ? "ok" : "not ok", " 41\n";
print $Collator->lt('V', 'W') ? "ok" : "not ok", " 42\n";
print $Collator->lt('W', 'X') ? "ok" : "not ok", " 43\n";
print $Collator->lt('X', 'Y') ? "ok" : "not ok", " 44\n";
print $Collator->lt('Y', 'Z') ? "ok" : "not ok", " 45\n";
print $Collator->lt('Z', 'ˆŸ') ? "ok" : "not ok", " 46\n";
print $Collator->lt('ˆŸ', 'ê¤') ? "ok" : "not ok", " 47\n";
print $Collator->lt('ê¤', '¬') ? "ok" : "not ok", " 48\n";


print $Collator->eq('', 'J') ? "ok" : "not ok", " 49\n";
print $Collator->eq('', 'K') ? "ok" : "not ok", " 50\n";
print $Collator->eq('', 'Þß') ? "ok" : "not ok", " 51\n";
print $Collator->eq('', 'ßÞ') ? "ok" : "not ok", " 52\n";
print $Collator->eq('', 'ü') ? "ok" : "not ok", " 53\n";

my $box = join('', pack 'n*', 0x849f..0x84be);
print $Collator->eq('',  $box) ? "ok" : "not ok", " 54\n";
print $Collator->gt('a', $box) ? "ok" : "not ok", " 55\n";
print $Collator->lt('a'.$box, $box.'b') ? "ok" : "not ok", " 56\n";
print $Collator->eq('a'.$box, $box.'a') ? "ok" : "not ok", " 57\n";
print $Collator->gt('b'.$box, $box.'a') ? "ok" : "not ok", " 58\n";

