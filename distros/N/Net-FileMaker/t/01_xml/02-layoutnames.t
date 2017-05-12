use strict; 
use warnings;

use Test::More;

unless ( $ENV{FMS_HOST} && $ENV{FMS_USER} && $ENV{FMS_PASS} )
{
    plan( skip_all => "FileMaker Server and authentication not declared" );
}

use_ok('Net::FileMaker');
use_ok('Net::FileMaker::XML');

# Direct access the package 
my $fmx = Net::FileMaker::XML->new( host => $ENV{FMS_HOST});
ok($fmx, 'Directly constructed Net::FileMaker::XML');
my $dbx = $fmx->dbnames;

# This test assumes that database 
if(ref($dbx) eq 'ARRAY')
{
        my $fmdb = $fmx->database(db => $dbx->[0], user => $ENV{FMS_USER}, pass => $ENV{FMS_PASS});
        my $layouts = $fmdb->layoutnames;
        is(ref($layouts), 'ARRAY', 'layoutnames returned arrayref');   
}

done_testing();

