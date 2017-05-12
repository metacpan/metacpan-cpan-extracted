BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use PApp::Recode ();
use Encode ();
$loaded = 1;
print "ok 1\n";
use utf8;

$c = PApp::Recode::Pconv::open "iso-8859-1", "UTF-8";

print +($c->convert(Encode::encode_utf8("\xfc\xf6\xe4")) eq "\xfc\xf6\xe4" ? "" : "not " ), "ok 2\n";
print +(eval {$c->convert_fresh("\x{2601}"); 1} ? "not " : ""), "ok 3\n";

$c = new PApp::Recode::Pconv "iso-8859-1", "utf-8", sub {
   sprintf "<%04x>", $_[0];
};

print +($c->convert("a\x{2601}b\x{2602}c") eq "a<2601>b<2602>c" ? "" : "not "), "ok 4\n";

