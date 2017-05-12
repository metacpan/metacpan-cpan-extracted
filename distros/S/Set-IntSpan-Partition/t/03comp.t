use Test::More;
use Set::IntSpan;
use Set::IntSpan::Partition;
use List::Util qw/sum/;
use List::MoreUtils qw/uniq/;

my $ran = 0;
for my $round (1 .. 100) {
  my $number_of_spans = int rand(10);

  my @spans = map {
    my $number_of_ints = int rand(100);
    Set::IntSpan->new([ map { int rand(100) } 1 .. $number_of_ints ])
  } 1 .. $number_of_spans;

  my %h = Set::IntSpan::Partition::intspan_partition_map(@spans);
  while (my ($k, $v) = each %h) {
    my $all = Set::IntSpan->new;
    $all->U($_) for @$v;
    ok($spans[$k]->equal($all), 'union same as parent');
    my $sum = sum map { $_->size } @$v;
    ok($sum == $spans[$k]->size, 'same size');
    $ran += 2;
  }

  my @old = Set::IntSpan::Partition::intspan_partition(@spans);
  my @new = uniq map @$_, values %h;
  my $old_str = join '!', sort map { "$_" } @old;
  my $new_str = join '!', sort map { "$_" } @new;
  ok($old_str eq $new_str, '...');
  $ran++;
}

done_testing($ran);
