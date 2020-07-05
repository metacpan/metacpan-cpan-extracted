use Test2::V0;
use List::Util qw(shuffle);
use SkewHeap::PP;

my $count    = 500;
my @ordered  = 1..$count;
my @shuffled = shuffle(@ordered);

sub compare {
  my ($a, $b) = @_;
  return $a <=> $b;
}

subtest('default interface' => sub{
  ok(my $s = skew(\&compare), 'skew');
  is(skew_count($s), 0, 'skew_count: initially 0');
  ok(skew_is_empty($s), 'skew_is_empty: initially true');

  my $new_size = skew_put($s, shuffle(@shuffled));
  is($new_size, $count, 'skew_put: expected size');
  ok(!skew_is_empty($s), 'skew_is_empty: false after put');
  is(skew_count($s), $count, 'skew_count: expected size after put');

  my @taken = skew_take($s, $count + 10);
  is(scalar(@taken), $count, 'skew_take: expected number of results, even with ask > count');
  is(skew_count($s), 0, 'skew_count: 0 after take');
  ok(skew_is_empty($s), 'skew_is_empty: true after take');
  is(\@taken, \@ordered, 'skew_take: results in expected order');

  for (shuffle(@shuffled)) {
    skew_put($s, $_);
  }

  undef @taken;
  for (@ordered) {
    my $got = skew_take($s);
    push @taken, $got;
  }

  is(\@taken, \@ordered, 'skew_put + skew_take - single item at a time');
});

subtest('object interface' => sub{
  ok(my $s = SkewHeap::PP->new(\&compare), 'skew');
  is($s->count(), 0, 'count: initially 0');
  ok($s->is_empty(), 'is_empty: initially true');

  my $new_size = $s->put(shuffle(@shuffled));
  is($new_size, $count, 'put: expected size');
  ok(!$s->is_empty(), 'is_empty: false after put');
  is($s->count(), $count, 'count: expected size after put');

  my @taken = $s->take($count + 10);
  is(scalar(@taken), $count, 'take: expected number of results, even with ask > count');
  is($s->count(), 0, 'count: 0 after take');
  ok($s->is_empty(), 'is_empty: true after take');
  is(\@taken, \@ordered, 'take: results in expected order');

  ok($s->put(42), 'put: single item');
  is($s->take(), 42, 'take: single item');
});

=comment
subtest('destructive merge' => sub{
  my $a = SkewHeap::PP->new(\&compare);
  my $b = SkewHeap::PP->new(\&compare);
  my $c = SkewHeap::PP->new(\&compare);

  $a->put(1..10);
  $b->put(11..20);
  $c->put(21..30);

  $a->merge($b, $c);

  is($a->count(), 30, 'a has expected count');
  is($b->count(), 0, 'b has no remaining items');
  is($c->count(), 0, 'c has no remaining items');
  is([$a->take(30)], [1..30], 'a contains expected contents');
});

subtest('non-destructive merge' => sub{
  my $a = SkewHeap::PP->new(\&compare);
  my $b = SkewHeap::PP->new(\&compare);
  my $c = SkewHeap::PP->new(\&compare);

  $a->put(1..10);
  $b->put(11..20);
  $c->put(21..30);

  my $d = $a->merge_safe($b, $c);

  is($a->count(), 10, 'a - count intact');
  is($b->count(), 10, 'b - count intact');
  is($c->count(), 10, 'c - count intact');
  is($d->count(), 30, 'd - expected count');

  is([$a->take($a->count())], [1..10], 'a - expected contents');
  is([$b->take($b->count())], [11..20], 'b - expected contents');
  is([$c->take($c->count())], [21..30], 'c - expected contents');
  is([$d->take($d->count())], [1..30], 'd - expected contents');
});
=cut

done_testing();
