use Pg::Loader::Misc;
use Test::More qw( no_plan );
use Test::Exception;

*subset = \&Pg::Loader::Misc::subset;

my $a = [qw( one two three four )];
my $b = [qw( three four )];


ok subset($a,$b);
ok subset( [1..5],[2] );
ok subset( [1..5],[2..3] );
ok subset( [1..5],[1..5] );
ok subset( [1..5],[] );
ok subset( [1..5], undef );
ok subset( undef, undef );
ok subset( [], [] );
ok ! subset( [], [3] );
ok subset( $a, [] );
