# Run via 'make test' or 'perl 10-Data-BoxFormat-read_dbox-twocol.t'

use strict;
use warnings;

use Data::Dumper;

use Test::More;
BEGIN {
  use FindBin qw( $Bin );
  use lib ("$Bin/../lib/");
  use_ok('Table::BoxFormat');
};


my $DAT = "$Bin/dat";
   # /home/doom/End/Cave/SkullPlot/Wall/Data-BoxFormat/t/dat

   # /home/doom/End/Cave/SkullPlot/Wall/Data-BoxFormat/t/dat/expensoids-twocol-psql.dbox

   # expensoids-twocol-psql.dbox



{
  my $test_name = "Testing read method on two columns of data";

  my $expected = [
                  [ 'date',       'tot'     ],
                  [ '2010-10-01', '618246'  ],
                  [ '2010-11-01', '218866'  ],
                  [ '2011-01-01', '191239'  ],
                  [ '2010-12-01', '191239'  ],
                  [ '2010-09-01', '613122'  ],
        ];

  my $format = 'psql';

  my $input_file = "$DAT/expensoids-twocol-psql.dbox";
  my $bxs =
    Table::BoxFormat->new(
                     input_file => $input_file,
                    );

  my $data = $bxs->read_dbox; # array of arrays, header in first row

  # print Dumper( $data ) , "\n";

  is_deeply( $data, $expected, "$test_name on $format format" );
}

done_testing();
