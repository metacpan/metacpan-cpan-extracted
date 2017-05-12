
BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(toupper tolower);

$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

sub stricmp { toupper($_[0]) cmp toupper($_[1]) }

print  0 == stricmp('', '')
  ? "ok" : "not ok", " ", ++$loaded, "\n";
print -1 == stricmp('', "\0")
  ? "ok" : "not ok", " ", ++$loaded, "\n";
print  0 == stricmp('A', 'a')
  ? "ok" : "not ok", " ", ++$loaded, "\n";
print -1 == stricmp('講習', '講縮')
  ? "ok" : "not ok", " ", ++$loaded, "\n";
print  0 == stricmp('プログラミングPerl',  'プログラミングPERL')
  ? "ok" : "not ok", " ", ++$loaded, "\n";
print -1 == stricmp('プログラミングPerl',  'プログラミンバPERL')
  ? "ok" : "not ok", " ", ++$loaded, "\n";

