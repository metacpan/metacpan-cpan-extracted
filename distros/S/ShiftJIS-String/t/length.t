
BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}

use ShiftJIS::String qw(length);
$^W = 1;
$loaded = 1;
print "ok 1\n";

#####

print 0 eq length("")
  ? "ok" : "not ok", " 2\n";

print 3 == length("abc")
  ? "ok" : "not ok", " 3\n";

print 5 == length("±²³´µ")
  ? "ok" : "not ok", " 4\n";

print 10 == length("‚ ‚©‚³‚½‚È‚Í‚Ü‚â‚ç‚í")
  ? "ok" : "not ok", " 5\n";

print 9 == length('AIUEO“ú–{Š¿Žš')
  ? "ok" : "not ok", " 6\n";

print 5 == length("+15.3")
  ? "ok" : "not ok", " 7\n";

print 1 == length('Q')
  ? "ok" : "not ok", " 8\n";

print 3 == length(123)
  ? "ok" : "not ok", " 9\n";

print 11 == length("‚ ‚©‚³‚½‚È\000‚Í‚Ü‚â‚ç‚í")
  ? "ok" : "not ok", " 10\n";

print 12 == length("AIU\000EO“ú–{\000Š¿Žš\x00")
  ? "ok" : "not ok", " 11\n";

1;
__END__
