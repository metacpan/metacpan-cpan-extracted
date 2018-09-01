use Test::More tests => 2;

use Repetition::Interval;

my $sched = Repetition::Interval->new();
my $new_avg = $sched->calculate_new_mean(4, 1, undef);
my $next_review = $sched->schedule_next_review(4, 1, $new_avg);
my $next_sec = $sched->schedule_next_review_seconds(4, 1, $new_avg);

is(2, $next_review, "next review is 2");
is(2*86400, $next_sec, "next review is 2 days seconds");
