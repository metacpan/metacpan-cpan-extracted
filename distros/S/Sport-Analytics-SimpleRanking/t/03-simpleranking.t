#!perl -T

use Test::More tests => 20;

BEGIN {
    use_ok( 'Sport::Analytics::SimpleRanking' ) || print "Bail out!
";
}

my $stats = Sport::Analytics::SimpleRanking->new();

my $games = [
    "ARI,17,SF,20", "BAL,20,CIN,27", "NYG,35,DAL,45", "CHI,3,SD,14",
    "TB,6,SEA,20", "DET,36,OAK,21", "PIT,34,CLE,7", "ATL,3,MIN,24",
    "MIA,13,WAS,16", "CAR,27,STL,13", "KC,3,HOU,20", "PHI,13,GB,16",
    "TEN,13,JAC,10", "DEN,15,BUF,14", "NE,38,NYJ,14", "NO,10,IND,41",
    "WAS,20,PHI,12", "SD,14,NE,38", "OAK,20,DEN,23", "NYJ,13,BAL,20",
    "KC,10,CHI,20", "SEA,20,ARI,23", "MIN,17,DET,20", "DAL,37,MIA,20",
    "NO,14,TB,31", "CIN,45,CLE,51", "SF,17,STL,16", "HOU,34,CAR,21",
    "GB,35,NYG,13", "IND,22,TEN,20", "ATL,7,JAC,13", "BUF,3,PIT,26",
    "TEN,31,NO,14", "DAL,34,CHI,10", "NYG,24,WAS,17", "CAR,27,ATL,20",
    "JAC,23,DEN,14", "CLE,24,OAK,26", "CIN,21,SEA,24", "ARI,23,BAL,26",
    "MIA,28,NYJ,31", "BUF,7,NE,38", "SD,24,GB,31", "IND,30,HOU,24",
    "DET,21,PHI,56", "SF,16,PIT,37", "STL,3,TB,24", "MIN,10,KC,13",
    "NE,34,CIN,13", "PHI,3,NYG,16", "PIT,14,ARI,21", "KC,30,SD,16",
    "DEN,20,IND,38", "TB,20,CAR,7", "SEA,23,SF,3", "HOU,16,ATL,26",
    "NYJ,14,BUF,17", "OAK,35,MIA,17", "STL,7,DAL,35", "CHI,27,DET,37",
    "BAL,13,CLE,27", "GB,23,MIN,16", "DAL,25,BUF,24", "CHI,27,GB,20",
    "SD,41,DEN,3", "BAL,9,SF,7", "TB,14,IND,33", "MIA,19,HOU,22",
    "DET,3,WAS,34", "ARI,34,STL,31", "CAR,16,NO,13", "SEA,0,PIT,21",
    "ATL,13,TEN,20", "JAC,17,KC,7", "NYJ,24,NYG,35", "CLE,17,NE,34",
    "NYG,31,ATL,10", "NO,28,SEA,17", "NE,48,DAL,27", "OAK,14,SD,28",
    "CAR,25,ARI,10", "HOU,17,JAC,37", "WAS,14,GB,17", "TEN,10,TB,13",
    "MIA,31,CLE,41", "MIN,34,CHI,31", "CIN,20,KC,27", "STL,3,BAL,22",
    "PHI,16,NYJ,9", "MIN,14,DAL,24", "STL,6,SEA,33", "CHI,19,PHI,16",
    "KC,12,OAK,10", "NYJ,31,CIN,38", "ARI,19,WAS,21", "ATL,16,NO,22",
    "BAL,14,BUF,19", "SF,15,NYG,33", "NE,49,MIA,28", "TEN,38,HOU,36",
    "TB,16,DET,23", "PIT,28,DEN,31", "IND,29,JAC,7", "WAS,7,NE,52",
    "NO,31,SF,10", "HOU,10,SD,35", "JAC,24,TB,23", "BUF,13,NYJ,3",
    "OAK,9,TEN,13", "PHI,23,MIN,16", "PIT,24,CIN,13", "DET,16,CHI,7",
    "IND,31,CAR,7", "NYG,13,MIA,10", "CLE,27,STL,20", "GB,19,DEN,13",
    "SF,16,ATL,20", "SD,17,MIN,35", "CAR,7,TEN,20", "DEN,7,DET,44",
    "ARI,10,TB,17", "CIN,21,BUF,33", "JAC,24,NO,41", "WAS,23,NYJ,20",
    "GB,33,KC,22", "DAL,38,PHI,17", "NE,24,IND,20", "HOU,24,OAK,17",
    "SEA,30,CLE,33", "BAL,7,PIT,38", "CHI,17,OAK,6", "DAL,31,NYG,20",
    "DET,21,ARI,31", "CIN,21,BAL,7", "JAC,28,TEN,13", "ATL,20,CAR,13",
    "PHI,33,WAS,25", "CLE,28,PIT,31", "STL,37,NO,29", "BUF,13,MIA,10",
    "DEN,27,KC,11", "MIN,0,GB,34", "IND,21,SD,23", "SF,0,SEA,24",
    "WAS,23,DAL,28", "STL,13,SF,9", "CHI,23,SEA,30", "PIT,16,NYJ,19",
    "ARI,35,CIN,27", "OAK,22,MIN,29", "CAR,17,GB,31", "NYG,16,DET,10",
    "KC,10,IND,13", "NO,10,HOU,23", "SD,17,JAC,24", "CLE,33,BAL,30",
    "TB,31,ATL,7", "MIA,7,PHI,17", "NE,56,BUF,10", "NYJ,3,DAL,34",
    "GB,37,DET,26", "BAL,14,SD,32", "DEN,34,CHI,37", "SF,37,ARI,31",
    "MIN,41,NYG,17", "BUF,14,JAC,36", "TEN,6,CIN,35", "WAS,13,TB,19",
    "SEA,24,STL,19", "HOU,17,CLE,27", "NO,31,CAR,6", "OAK,20,KC,17",
    "IND,31,ATL,13", "TEN,20,DEN,34", "PHI,28,NE,31", "GB,27,DAL,37",
    "MIA,0,PIT,3", "TB,27,NO,23", "CLE,21,ARI,27", "DEN,20,OAK,34",
    "HOU,20,TEN,28", "DET,10,MIN,42", "BUF,17,WAS,16", "NYJ,40,MIA,13",
    "SEA,28,PHI,24", "JAC,25,IND,28", "ATL,16,STL,28", "SF,14,CAR,31",
    "SD,24,KC,10", "NYG,21,CHI,16", "NE,27,BAL,24", "CIN,10,PIT,24",
    "CHI,16,WAS,24", "IND,44,BAL,20", "KC,7,DEN,41", "CLE,24,NYJ,18",
    "PIT,13,NE,34", "MIN,27,SF,7", "ARI,21,SEA,42", "NYG,16,PHI,13",
    "CAR,6,JAC,37", "SD,23,TEN,17", "TB,14,HOU,28", "MIA,17,BUF,38",
    "OAK,7,GB,38", "DAL,28,DET,27", "STL,10,CIN,19", "NO,34,ATL,14",
    "DET,14,SD,51", "PHI,10,DAL,6", "IND,21,OAK,14", "BAL,16,MIA,22",
    "ARI,24,NO,31", "ATL,3,TB,37", "GB,33,STL,14", "BUF,0,CLE,8",
    "JAC,29,PIT,22", "SEA,10,CAR,13", "TEN,26,KC,17", "NYJ,10,NE,20",
    "CIN,13,SF,20", "DEN,13,HOU,31", "CHI,13,MIN,20", "WAS,22,NYG,10",
    "WAS,32,MIN,21", "MIA,7,NE,28", "BAL,6,SEA,27", "NYJ,6,TEN,10",
    "ATL,27,ARI,30", "TB,19,SF,21", "PHI,38,NO,23", "KC,20,DET,25",
    "NYG,38,BUF,21", "OAK,11,JAC,49", "CLE,14,CIN,19", "GB,7,CHI,35",
    "HOU,15,IND,38", "DAL,20,CAR,13", "PIT,41,STL,24", "DEN,3,SD,23",
    "STL,19,ARI,48", "SD,30,OAK,17", "KC,10,NYJ,13", "DAL,6,WAS,27",
    "PIT,21,BAL,27", "MIN,19,DEN,22", "SEA,41,ATL,44", "CIN,38,MIA,25",
    "BUF,9,PHI,17", "CAR,31,TB,23", "JAC,28,HOU,42", "NO,25,CHI,33",
    "DET,13,GB,34", "SF,7,CLE,20", "NE,38,NYG,35", "TEN,16,IND,10",
];

$stats->load_data( $games );
my $oldmov = $stats->mov();
my $srs = $stats->simpleranking();
my $mov = $stats->mov();
my $sos = $stats->sos();


diag( "Comparing calculated values to ones found on Pro Football Reference here:\n" );
diag( "http://www.pro-football-reference.com/years/2007/\n" );

my $dd_srs_ne  = 20.1;
my $dd_srs_ind = 12.0;
my $dd_srs_dal  = 9.5;
my $dd_srs_bal = -6.7;
my $dd_srs_stl = -13.0;

cmp_ok( scalar keys %$oldmov, '==', 32, 'correct number of teams.');
cmp_ok( scalar keys %$mov, '==', 32, 'correct number of teams.');
cmp_ok( scalar keys %$srs, '==', 32, 'correct number of teams.');
cmp_ok( scalar keys %$sos, '==', 32, 'correct number of teams.');

my $sum = 0;
$sum += $mov->{$_} for ( keys %$mov );
my $srssum = 0;
$srssum += $srs->{$_} for ( keys %$srs );
 
cmp_ok( abs( $sum ), '<', 0.0005, '$mov sums to about zero.');
cmp_ok( abs( $srssum ), '<', 0.0005, '$srssum sums to about zero.');
cmp_ok (abs($srs->{NE} - $dd_srs_ne ) ,'<',0.05, 'NE calculated matches Pro Football Reference.');
cmp_ok (abs($srs->{IND} - $dd_srs_ind) ,'<',0.05, 'IND calculated matches Pro Football Reference.');
cmp_ok (abs($srs->{DAL} - $dd_srs_dal) ,'<',0.05, 'DAL calculated matches Pro Football Reference.');
cmp_ok (abs($srs->{BAL} - $dd_srs_bal) ,'<',0.05, 'BAL calculated matches Pro Football Reference.');
cmp_ok (abs($srs->{STL} - $dd_srs_stl) ,'<',0.05, 'STL calculated matches Pro Football Reference.');

my $games = $stats->total_games();

is( $games, 256,'There are 256 games in this data set');
my $team_data = $stats->team_stats();

is ( $team_data->{NE}->{wins}, 16, 'New England won 16 games in 2007');
is ( $team_data->{NYG}->{wins}, 10, 'New York won 10 games in 2007');
is ( $team_data->{PHI}->{points_for}, 336, 'Philadelphia scored 336 points in 2007');
is ( $team_data->{PHI}->{points_against}, 300, 'Philadelphia allowed 300 points in 2007');

my $pred2 = $stats->pythag();

cmp_ok(abs( $pred2->{PHI} - 0.5564),'<',0.0001,"Philadelphia Pythag in 2007 with exponent 2 is about .5664");

diag( "Comparing calculated values to one found on Pro Football Reference here:\n" );
diag( "http://www.pro-football-reference.com/teams/phi/2007.htm\n" );

my $pred237 = $stats->pythag(2.37);

cmp_ok(abs( 16*$pred237->{PHI} - 9.1),'<',0.1,"Philadelphia Pythag in 2007 with exponent 2.37 is about 9.1 wins");

my $exponent;
my $predicted = $stats->pythag( \$exponent, best => 1 );

cmp_ok(abs($exponent - 2.508),'<',0.01,"2007 Pythagorean best fit to exponent is about 2.508");
