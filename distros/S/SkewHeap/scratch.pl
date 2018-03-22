use SkewHeap;

my $count = $ARGV[0] // 100_000;
print "Count: $count\n";

my $h = SkewHeap->new(sub{ $a <=> $b});

$h->put(1 .. $count);

foreach my $i (1 .. $count) {
  my $v = $h->take;
}
