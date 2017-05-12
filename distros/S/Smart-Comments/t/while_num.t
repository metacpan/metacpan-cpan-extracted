use Smart::Comments;
use Test::More 0.99 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $count = 0;

LABEL:

while ($count < 100) {    ### while:===[%]   done (%)
    $count++;
}

close *STDERR;
open *STDERR, '>-';

my $prev_count = -1;
sub test_format_and_incr {
    my ($n, $output) = @_;
    subtest "Iteration $n" => sub {
        ok $output =~ m/while:=*\[(\d+)\]\s+done \(\1\)/ => 'Correct format';
        my $count = $1;
        cmp_ok $count, '>', $prev_count  => 'Correctly incremented';
        $prev_count = $count;
    };
}

my @outputs = grep /\S/, split /\r/, $STDERR;

for my $n (0..5) {
    test_format_and_incr($n, $outputs[$n]);
}
