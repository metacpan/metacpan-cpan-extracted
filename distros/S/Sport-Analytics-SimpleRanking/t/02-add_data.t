#!perl -T

use Test::More tests => 19;

BEGIN {
    use_ok( 'Sport::Analytics::SimpleRanking' ) || print "Bail out!
";
}

diag( "Testing Sport::Analytics::SimpleRanking $Sport::Analytics::SimpleRanking::VERSION, Perl $], $^X" );

my $stats = Sport::Analytics::SimpleRanking->new();




my $games = [
    "Boston,13,Atlanta, 27",
    "Dallas,17,Chicago,21",
    "Eugene,30,Fairbanks,41",
    "Atlanta,15,Chicago,3",
    "Eugene,21,Boston,24",
    "Fairbanks,17,Dallas,7",
];

cmp_ok( $stats->load_data( $games ),'==',1,'Data were loaded into the object');

my $bad_data = [
 "A,B,C","D,E,F"
];

eval { $stats->add_data( $bad_data ) };
$@ ||=0;

like( $@, qr/score is undefined/, 'add_data fails with bad_data');

my $more_games = [
    "Dallas,19,Atlanta,7",
    "Boston,9,Fairbanks,31",
    "Chicago,10,Eugene,30",
];

cmp_ok ( $stats->add_data( $more_games ), '==', 1, 'Extra data were loaded into the object');

my $tot_games = $stats->total_games();
my $teams = $stats->total_teams();
my $wins = $stats->total_wins();
my $home_wins = $stats->home_wins();
my $home_win_pct = $stats->home_win_pct();
my $win_margin = $stats->win_margin();
my $win_score = $stats->win_score();
my $loss_score = $stats->loss_score();
my $avg_score = $stats->avg_score();
my $test_league = $stats->team_stats();

my $mov = $stats->mov();
is ( $tot_games,9,'There are 9 games in this set.');
is ( $teams,6,'There are 6 teams in this data set.');
is ( $wins,9,'There are 9 wins in this data set.');
is ( $home_wins,6,'There are 6 home wins in this data set.');
is ( $win_margin,12,'The average win margin is 12.');
cmp_ok ( abs( $win_score - 25.0),'<',0.0001, 'Win score is about 25');
cmp_ok ( abs( $loss_score - 13.0),'<',0.001, 'Losing score is about 13.0');
cmp_ok ( abs( $avg_score - 19.0),'<',0.001, 'Average score is about 19.0');
cmp_ok ( abs( $home_win_pct - 0.66666),'<',0.001, 'Home win pct is 2/3.');
is ( $test_league->{Fairbanks}{wins},3,'Fairbanks has won 3 games');
cmp_ok ( scalar keys %$mov,'==',6,'$mov has 6 members');
cmp_ok ( scalar keys %$mov,'==',6,'$mov has 6 members');
cmp_ok( $mov->{Eugene},'==',2,'Team Eugene has a mov of 2');
cmp_ok( abs($mov->{Dallas} + 0.66666),'<',0.001,'Team Dallas has a mov of -2/3');


eval { $stats->load_data( $games ) };
$@ = 0 unless ( $@ );

like( $@,qr/only load data once/, 'This is a one use object.');
