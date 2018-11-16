# Test file created outside of h2xs framework.
# Run this like so: `perl 90-Data-BoxFormat-Unicode-CharClasses.t'
#   doom@kzsu.stanford.edu     2016/12/23 00:50:01

use Test::More;

use warnings;
use strict;
$|=1;
use Data::Dumper;

ok(1, "If we made it this far, we're ok. All modules are loaded.");

BEGIN {
  use FindBin qw( $Bin );
  use lib ("$Bin/../lib/");
  use_ok( 'Table::BoxFormat::Unicode::CharClasses', ':all' );
};

my @lines =
  (
   '   id |    date    |   type    | amount',
   '  ----+------------+-----------+--------',
   '    1 | 2010-09-01 | factory   | 146035',
   '    2 | 2010-10-01 | factory   | 208816',
   '    4 | 2011-01-01 | factory   | 191239',
   '    6 | 2010-09-01 | marketing | 467087',
   '    7 | 2010-10-01 | marketing | 409430',
  );

{ my $test_name = "Testing IsHor";

  my @hits;
  foreach my $line ( @lines ) {
    $line =~ s/^\s*//;
    $line =~ s/\s*$//;

    push @hits, $line
      if( $line =~ m/^\p{IsHor}*$/ );
  }

  is( scalar( @hits ), 1 , "$test_name: just one hit" );

  my $expected = '----+------------+-----------+--------';

  is( $hits[0], $expected, "$test_name: matched the ruler line" );
}


{ my $test_name = "Testing IsCross";

  my @hits;
  foreach my $line ( @lines ) {
    $line =~ s/^\s*//;
    $line =~ s/\s*$//;

    push @hits, $line
      if( $line =~ m/\p{IsCross}/ );
  }

  is( scalar( @hits ), 1 , "$test_name: just one hit" );

  my $expected = '----+------------+-----------+--------';

  is( $hits[0], $expected, "$test_name: matched the ruler line" );
}


{ my $test_name = "Testing IsDelim";

  my @hits;
  foreach my $line ( @lines ) {
    $line =~ s/^\s*//;
    $line =~ s/\s*$//;

    push @hits, $line
      if( $line =~ m/\p{IsDelim}/ );
  }

  is( scalar( @hits ), 6 , "$test_name: checking for 6 hits" );

  my $expected = 'id |    date    |   type    | amount';
  is( $hits[0], $expected, "$test_name: first match should be the header line" );
}


done_testing();
