use Test::More;

# score => expected interval
my @intervals = (
    [4 => 2],
    [4 => 4],
    [4 => 8],
    [4 => 14],
    [4 => 21],
    [4 => 31],
    [4 => 42],
    [4 => 55],
    [4 => 70],
    [4 => 86],
);

plan tests => scalar(@intervals);

use Repetition::Interval;
my $sched = Repetition::Interval->new();

my $avg = undef;
my $reviews = 1;

foreach my $p ( @intervals ) {
   my $new_avg = $sched->calculate_new_mean($p->[0], $reviews, $avg);
   my $next_review = $sched->schedule_next_review($p->[0], $reviews, $new_avg);
   is($next_review, $p->[1], "next review should be " . $p->[1]);
   $avg = $new_avg;
   $reviews++;
}
