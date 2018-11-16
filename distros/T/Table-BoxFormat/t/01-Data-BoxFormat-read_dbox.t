# Run via 'make test' or 'perl 01-Data-BoxFormat-read_dbox.t'

use strict;
use warnings;
use 5.10.0;
use Data::Dumper::Concise;

use Test::More;
BEGIN {
  use FindBin qw( $Bin );
  use lib ("$Bin/../lib/");
  use_ok('Table::BoxFormat');
};


my $DAT = "$Bin/dat";
   #  /home/doom/End/Cave/SkullPlot/Wall/Data-Boxes/t/dat

{
  my $test_name = "Testing read method";

  my $expected = [
          [ 'id', 'date',       'type',      'amount' ],
          [  '1', '2010-09-01', 'factory',   '146035' ],
          [  '2', '2010-10-01', 'factory',   '208816' ],
          [  '3', '2010-11-01', 'factory',   '218866' ],
          [  '4', '2010-12-01', 'factory',   '191239' ],
          [  '5', '2011-01-01', 'factory',   '191239' ],
          [  '6', '2010-09-01', 'marketing', '467087' ],
          [  '7', '2010-10-01', 'marketing', '409430' ]
        ];

  my $format = 'psql';

  my $input_file = "$DAT/expensoids-psql.dbox";
  my $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  my $data = $bxs->read_dbox; # array of arrays, header in first row

  # print Dumper( $data ) , "\n";

  is_deeply( $data, $expected, "$test_name on $format format" );


  ###
  $format = 'psql_unicode';

  $input_file = "$DAT/expensoids-psql_unicode.dbox";

  $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  $data = $bxs->read_dbox; # array of arrays, header in first row

  is_deeply( $data, $expected, "$test_name on $format format" );

  ###
  $format = 'mysql';

  $input_file = "$DAT/expensoids-mysql.dbox";

  $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  $data = $bxs->read_dbox; # array of arrays, header in first row

  is_deeply( $data, $expected, "$test_name on $format format" )
    or say Dumper( $data );

}



done_testing();
