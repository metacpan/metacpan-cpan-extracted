use strict;
use warnings;

use Test::More;

unless ( $ENV{FMS_HOST} )
{
    plan( skip_all => "FileMaker Server not declared" );
}

use_ok('Net::FileMaker');
use_ok('Net::FileMaker::XML');

# Construct through Net::FileMaker
my $fm = Net::FileMaker->new( host => $ENV{FMS_HOST}, type => 'xml');
ok($fm, 'Net::FileMaker::XML constructed through Net::FileMaker');
my $db = $fm->dbnames;
ok($db, 'Databases found');

# Direct access the package
my $fmx = Net::FileMaker::XML->new( host => $ENV{FMS_HOST});
ok($fmx, 'Directly constructed Net::FileMaker::XML');
my $dbx = $fmx->dbnames;
ok($dbx, 'Databases found');

done_testing();
