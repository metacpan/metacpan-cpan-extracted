print "1..1\n";

use Statistics::Frequency;

my $f = Statistics::Frequency->new();

print $f->isa('Statistics::Frequency') ? "ok 1\n" : "not ok 1\n";

