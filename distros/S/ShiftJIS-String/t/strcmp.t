
BEGIN { $| = 1; print "1..58\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(:cmp mkrange);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

print strcmp('',   'A')  < 0
  ? "ok" : "not ok", " 2\n";

print strcmp('A',  'a')  < 0
  ? "ok" : "not ok", " 3\n";

print strcmp('a',  '±')  < 0
  ? "ok" : "not ok", " 4\n";

print strcmp('±',  '‚`') < 0
  ? "ok" : "not ok", " 5\n";

print strcmp('‚`', '‚ ') < 0
  ? "ok" : "not ok", " 6\n";

print strcmp('‚ ', 'ƒA') < 0
  ? "ok" : "not ok", " 7\n";

print strcmp('ƒA', 'ˆŸ') < 0
  ? "ok" : "not ok", " 8\n";

print strcmp('ˆŸ', '˜r') < 0
  ? "ok" : "not ok", " 9\n";

print strcmp('˜r', '˜Ÿ') < 0
  ? "ok" : "not ok", " 10\n";

print strcmp('˜Ÿ', 'ê¤') < 0
  ? "ok" : "not ok", " 11\n";

print strcmp(123, 123) == 0
  ? "ok" : "not ok", " 12\n";

print strcmp(12,  11)  == 1
  ? "ok" : "not ok", " 13\n";

print strcmp(11,  12)  == -1
  ? "ok" : "not ok", " 14\n";

print strEQ(123, 123) eq (123 eq 123)
  ? "ok" : "not ok", " 15\n";

print strEQ(123, 124) eq (123 eq 124)
  ? "ok" : "not ok", " 16\n";

print strNE(123, 123) eq (123 ne 123)
  ? "ok" : "not ok", " 17\n";

print strNE(123, 124) eq (123 ne 124)
  ? "ok" : "not ok", " 18\n";

print strcmp('', '') == 0
  ? "ok" : "not ok", " 19\n";

print strEQ('', '')
  ? "ok" : "not ok", " 20\n";

print !strNE('', '')
  ? "ok" : "not ok", " 21\n";

print strLE('', '')
  ? "ok" : "not ok", " 22\n";

print !strLT('', '')
  ? "ok" : "not ok", " 23\n";

print strGE('', '')
  ? "ok" : "not ok", " 24\n";

print !strGT('', '')
  ? "ok" : "not ok", " 25\n";

print strcmp('', "\0") == -1
  ? "ok" : "not ok", " 26\n";

print !strEQ('', "\0")
  ? "ok" : "not ok", " 27\n";

print strNE('', "\0")
  ? "ok" : "not ok", " 28\n";

print strLE('', "\0")
  ? "ok" : "not ok", " 29\n";

print strLT('', "\0")
  ? "ok" : "not ok", " 30\n";

print !strGE('', "\0")
  ? "ok" : "not ok", " 31\n";

print !strGT('', "\0")
  ? "ok" : "not ok", " 32\n";

print strcmp("\0", '') == 1
  ? "ok" : "not ok", " 33\n";

print !strEQ("\0", '')
  ? "ok" : "not ok", " 34\n";

print strNE("\0", '')
  ? "ok" : "not ok", " 35\n";

print !strLT("\0", '')
  ? "ok" : "not ok", " 36\n";

print !strLE("\0", '')
  ? "ok" : "not ok", " 37\n";

print strGT("\0", '')
  ? "ok" : "not ok", " 38\n";

print strGE("\0", '')
  ? "ok" : "not ok", " 39\n";

print strcmp("\0", "\0") == 0
  ? "ok" : "not ok", " 40\n";

print strEQ("\0", "\0")
  ? "ok" : "not ok", " 41\n";

print !strNE("\0", "\0")
  ? "ok" : "not ok", " 42\n";

print strLE("\0", "\0")
  ? "ok" : "not ok", " 43\n";

print !strLT("\0", "\0")
  ? "ok" : "not ok", " 44\n";

print strGE("\0", "\0")
  ? "ok" : "not ok", " 45\n";

print !strGT("\0", "\0")
  ? "ok" : "not ok", " 46\n";

print strcmp("", 1) == -1
  ? "ok" : "not ok", " 47\n";

print strcmp(21, 11) == 1
  ? "ok" : "not ok", " 48\n";

print strNE('ABC',  'ABz')
  ? "ok" : "not ok", " 49\n";

print strLT('ABC',  'ABz')
  ? "ok" : "not ok", " 50\n";

print strGT('‚ ‚¨', '‚ ‚¢')
  ? "ok" : "not ok", " 51\n";

print strEQ('‚ ‚¨‚¢', '‚ ‚¨‚¢')
  ? "ok" : "not ok", " 52\n";

print strLT('‚ ‚ ±Š¿Žš', '‚ ‚ Š¿Žš')
  ? "ok" : "not ok", " 53\n";

print strLT("‚ ‚ \xA1", "‚ ‚ \x9D\x80")
  ? "ok" : "not ok", " 54\n";

print strGT("‚ ‚ \x82\xA1", "‚ ‚ \x82\x9D")
  ? "ok" : "not ok", " 55\n";

print strcmp("‚ \0×ƒ‰", "‚ \0ƒ‰×") == -1
  ? "ok" : "not ok", " 56\n";

{
  my $prev;
  my $here;
  my @char = mkrange("\0-\xfc\xfc");
  my @ret = (0) x 7;
  my $NG1 = 0;
  my $NG2 = 0;
  $prev = $here = '';
  foreach $here (@char) {
    ++$NG1 unless strcmp($prev, $here) < 0;
    ++$NG2 unless strLE($prev, $here);
    $prev = $here;
  }
  print $NG1 == 0 ? "ok" : "not ok", " 57\n";
  print $NG2 == 0 ? "ok" : "not ok", " 58\n";
}

1;

__END__
