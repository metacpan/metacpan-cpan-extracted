use strict; 
use warnings;

use Test::More;

unless ( $ENV{FMS_HOST} && $ENV{FMS_USER} && $ENV{FMS_PASS} && $ENV{FMS_LAYOUT} )
{
    plan( skip_all => "FileMaker Server and authentication not declared" );
}

use_ok('Net::FileMaker');
use_ok('Net::FileMaker::XML');
use_ok('Net::FileMaker::XML::ResultSet');


# Direct access the package 
my $fmx = Net::FileMaker::XML->new( host => $ENV{FMS_HOST});
ok($fmx, 'Directly constructed Net::FileMaker::XML');

my $dbx = $fmx->dbnames;
my $fmdb = $fmx->database(db => $dbx->[0], user => $ENV{FMS_USER}, pass => $ENV{FMS_PASS});
ok($fmdb,'Logged in');

my $layouts = $fmdb->layoutnames;
if(ref($layouts) eq 'ARRAY')
{
    my $records = $fmdb->findall(layout => $layouts->[0], params => { '-max' => 1})->rows;
    is(ref(@$records[0]), 'Net::FileMaker::XML::ResultSet::Row', 'the first row of the RS is a Net::FileMaker::XML::ResultSet::Row');
}

done_testing();
