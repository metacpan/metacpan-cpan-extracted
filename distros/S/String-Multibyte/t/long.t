# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

use String::Multibyte;

my $mb = String::Multibyte->new('ShiftJIS',1);

$^W = 1;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$n = 3500;
$f = 10;
$len = $f * $n;

$sub = "0123456‚`‚ ˆŸ";
$str = $sub x $n;
$rev = "ˆŸ‚ ‚`6543210" x $n;

print $mb->islegal($str) ? "ok" : "not ok", " 2\n";

print ! $mb->islegal($str."\xFF") ? "ok" : "not ok", " 3\n";

print $mb->length($str) == $len ? "ok" : "not ok", " 4\n";

print $mb->index($str, "perl") == -1
  ? "ok" : "not ok", " 5\n";
print $mb->index($str.'‚o‚…‚’‚Œ', '‚…‚’‚Œ') == $len + 1
  ? "ok" : "not ok", " 6\n";
print $mb->rindex($str, "‚ ˆŸ") == $len - 2
  ? "ok" : "not ok", " 7\n";
print $mb->rindex($str, "perl") == -1
  ? "ok" : "not ok", " 8\n";

print $mb->strspn($str, $sub) == $len
  ? "ok" : "not ok", " 9\n";

print $mb->strcspn($str, "A") == $len
  ? "ok" : "not ok", " 10\n";

print $mb->strrev($str) eq $rev
  ? "ok" : "not ok", " 11\n";

print $mb->substr($str,-1) eq 'ˆŸ'
  ? "ok" : "not ok", " 12\n";

print $mb->substr($str,1000*$f,200*$f) eq ($sub x 200)
  ? "ok" : "not ok", " 13\n";

1;
__END__
