# Run via 'make test' or 'perl 03-Data-BoxFormat-read_dbox-sqlite3.t'

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

{  my $test_name = "Testing read method on sqlite3 variant";
  # Note, this is for sqlite data with ".header on" and ".mode column"

  my $expected = [
          [ 'id', 'date',       'type',      'amount'   ],
          [  '1', '2010-09-01', 'factory',   '146035.0' ],
          [  '2', '2010-10-01', 'factory',   '208816.0' ],
          [  '3', '2010-11-01', 'factory',   '218866.0' ],
          [  '4', '2010-12-01', 'factory',   '191239.0' ],
          [  '5', '2011-01-01', 'factory',   '191239.0' ],
          [  '6', '2010-09-01', 'marketing', '467087.0' ],
          [  '7', '2010-10-01', 'marketing', '409430.0' ]
        ];

  my $format = 'psql';

  my $input_file = "$DAT/expensoids-sqlite3.dbox";

  my $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  my $data = $bxs->read_dbox; # array of arrays, header in first row

  # print Dumper( $data ) , "\n";

  is_deeply( $data, $expected, "$test_name on $format format" );
}



done_testing();
