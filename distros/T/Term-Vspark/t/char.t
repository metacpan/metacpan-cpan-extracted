use Test::Most;

use Term::Vspark qw/show_graph/;
use utf8;

my $expected = <<EOF;
 0 
 1 #
 2 ##
 3 ###
 4 ####
 5 #####
EOF

my $graph = show_graph(
    values  => [0, 1, 2, 3, 4, 5],
    labels  => [0, 1, 2, 3, 4, 5],
    max     => 5,
    columns => 3 + 5,
    char    => '#',
);

is $graph, $expected;

done_testing;
