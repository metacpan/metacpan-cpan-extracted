# Run as 'make test' or 'perl Data-Boxes-Format-psql.t'

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
   #  /home/doom/End/Cave/SkullPlot/Wall/Data-Boxes/t/dat

{
  my $test_name = "Testing output_to_csv method";

  my $format = 'psql_unicode';

  my $input_file  = "$DAT/expensoids-psql_unicode.dbox";
  my $output_file = "$DAT/expensoids-psql_unicode.csv";
  my $bxs =
    Table::BoxFormat->new(
                     input_file  => $input_file,
                    );

  my $status = $bxs->output_to_csv( $output_file ); # output straight to csv file
  is( $status, 1, "$test_name: returns success code" );

  my $expected_file = qq{$DAT/expensoids_expected.csv};
  my $expected = do{ undef $/; open my $fh, '<', $expected_file; <$fh> };
  my $result   = do{ undef $/; open my $fh, '<', $expected_file; <$fh> };

  is_deeply( $result, $expected, "$test_name on $format format" );
}

done_testing();
