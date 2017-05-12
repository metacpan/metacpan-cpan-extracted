
BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

$dgc = $] < 5.008 ? undef : String::Multibyte->new('Grapheme');

print ! $dgc ||
    pack('U*', 0x300, 0, 0x0D, 0x41, 0x300, 0x301, 0x3042,
	0xD, 0xA, 0xAC00, 0x11A8) eq $dgc->strrev(
    pack('U*', 0xAC00, 0x11A8, 0xD, 0xA, 0x3042, 0x41, 0x300,
	0x301, 0xD, 0, 0x300))
    ? "ok" : "not ok", " 2\n";

print ! $dgc ||
    7 == $dgc->length(pack('U*', 0xAC00, 0x11A8, 0xD, 0xA, 0x3042,
	0x41, 0x300, 0x301, 0xD, 0, 0x300))
    ? "ok" : "not ok", " 3\n";

unless ($dgc) {
    for (4..9) { print "ok $_\n" }
} else {
    $reDGC = String::Multibyte->new('Grapheme')->{regexp};

print "\cM\cJ" =~ /^${reDGC}\z/
   && "\cM\cJ" !~ /^${reDGC}{2}\z/
    ? "ok" : "not ok", " 4\n";

print "\cM\cM" !~ /^${reDGC}\z/
   && "\cM\cM" =~ /^${reDGC}{2}\z/
    ? "ok" : "not ok", " 5\n";

print "\cJ\cJ" !~ /^${reDGC}\z/
   && "\cJ\cJ" =~ /^${reDGC}{2}\z/
    ? "ok" : "not ok", " 6\n";

print "\cJ\cM" !~ /^${reDGC}\z/
   && "\cJ\cM" =~ /^${reDGC}{2}\z/
    ? "ok" : "not ok", " 7\n";

$ct_cc = pack ('U*', 0x01, 0x300);

print $ct_cc !~ /^${reDGC}\z/
   && $ct_cc =~ /^${reDGC}{2}\z/
    ? "ok" : "not ok", " 8\n";

$hangul = pack ('U*', 0x1112, 0x1161, 0x11AB, 0x1100, 0x1173, 0x11AF);

print $hangul !~ /^${reDGC}\z/
   && $hangul =~ /^${reDGC}{2}\z/
    ? "ok" : "not ok", " 9\n";
}

1;
__END__
