BEGIN { push @ARGV, '--dbitest=33' }
use Pg::Loader::Columns;
use Test::More qw( no_plan );
use Test::Exception;

*requested_cols = \&Pg::Loader::Columns::requested_cols;

my @all = qw( fn ln exam score timeenter );

my $c  = { copy_columns => [qw( fn score )], attributes=>[@all]  };
my $o  = { only_cols    => '4-5'           , attributes=>[@all]   };
my $a  = { copy_columns=>[qw( fn score )]  , attributes=>[@all],
           only_cols => '4-5'};

my $ans1 = [ '(fn, score)', 'fn', 'score' ];
my $ans2 = [ '(score, timeenter)', 'score', 'timeenter' ];
my $ans3 = [ '('.join(', ', @all) . ')',  @all ];


is_deeply [requested_cols( $c  )], $ans1;
is_deeply [requested_cols( $o  )], $ans2; 

#is_deeply [requested_cols( {}   , [@all] )], $ans3; 

dies_ok   { requested_cols( $a )} ;
lives_ok  { requested_cols( $c )} ;

