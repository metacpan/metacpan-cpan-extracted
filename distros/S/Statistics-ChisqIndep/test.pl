use strict;
use Statistics::ChisqIndep;
use POSIX;

my $obs = [ [15, 68, 83], [23,47,65]];

my $chi = new Statistics::ChisqIndep;
$chi->load_data($obs);

$chi->print_summary();
