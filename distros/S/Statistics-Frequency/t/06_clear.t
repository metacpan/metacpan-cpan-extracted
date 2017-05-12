use Statistics::Frequency;

print "1..2\n";

my $f = Statistics::Frequency->new(map{($_)x$_}1..10);

$f->clear_data;

print ! defined $f->elements        ? "ok 1\n" : "not ok 1\n";
print ! defined $f->frequencies_sum ? "ok 2\n" : "not ok 2\n";


