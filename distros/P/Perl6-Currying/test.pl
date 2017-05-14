BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Perl6::Currying;
$loaded = 1;
print "ok 1\n";

my $print = sub ($ok,$val) { print "$ok $val\n" };

$print->("ok",2);

my $ok = $print.prebind(ok=>"ok");
$ok->(3);

my $four = $print.prebind(val=>4);
$four->("ok");


sub show($ok, $val) { print "$ok $val\n" }

show("ok",5);

$ok = &show.prebind(ok=>"ok");
$ok->(6);

*seven = prebind &show: (val=>7);
seven("ok");
