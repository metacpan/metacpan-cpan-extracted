use Test::More tests => 1;
use English qw( -no_match_vars ) ;

use strict;
use warnings;

my $code =<<'EOT'
  use String::LCSS_XS qw(lcss lcss_all);
  
  my $longest = lcss ( "zyzxx", "abczyzefg" );
  print $longest, "\n";

  my @result = lcss ( "zyzxx", "abczyzefg" );
  print "$result[0] ($result[1],$result[2])\n";

  my @results = lcss_all ( "ABBA", "BABA" );
  for my $result (@results) {
     print "$result->[0] ($result->[1],$result->[2])\n";
  }
EOT
;

eval $code;

ok(!$EVAL_ERROR, 'synopsis compiles') || diag $EVAL_ERROR;

