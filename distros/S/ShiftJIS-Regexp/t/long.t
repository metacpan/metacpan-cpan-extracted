############

use strict;
use vars qw($loaded);

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use ShiftJIS::Regexp qw(re);
$loaded = 1;
print "ok 1\n";

############

my $long = "0123泣A" x 15000;
$_ = "あいうえお".$long."アイウ". $long."エオ漢字シフ". $long."トＪＩＳ";
my $regex = re('(\R{padG})(\pK)');
my $pK = re('^\pK$');


my $cnt = 0;
while (/$regex/go) {
   print $2 =~ /$pK/o ? "ok " : "not ok ", $cnt + 2, "\n";
   $cnt++;
   die "seems to fall in infinite loop then stopped" if $cnt >= 20;
}

print $cnt == 8 ? "ok " : "not ok ", $cnt + 2, "\n";
