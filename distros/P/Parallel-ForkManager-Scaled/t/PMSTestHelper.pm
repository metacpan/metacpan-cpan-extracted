package PMSTestHelper;

use Moo;

has idle => ( is => 'rw' );

sub get_cpu_stats_diff { shift }
sub get_cpu_percents   { shift }

1;
