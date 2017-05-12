use Statistics::Frequency;

my $f = Statistics::Frequency->new(map{($_)x$_}1..10);
my $g = $f->copy_data;

print "1..", 2 + $f->elements, "\n";

print $f->elements        == $g->elements        ? "ok 1\n" : "not ok 1\n";
print $f->frequencies_sum == $g->frequencies_sum ? "ok 2\n" : "not ok 2\n";

my $t = 3;

for my $e ($f->elements) {
  print $f->frequency($e) == $g->frequency($e) ? "ok $t\n" : "not ok $t\n";
  $t++;
}


