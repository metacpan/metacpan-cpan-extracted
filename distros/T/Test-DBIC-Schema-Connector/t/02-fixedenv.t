use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::DBIC::Schema::Connector;
use TDSCTSchema;

my $tmpdir = tempdir;
my $testdb = $tmpdir.'/tempdir.sqlite';
my $testdsn = 'dbi:SQLite:dbname='.$testdb;

$ENV{WE_SET_THE_DSN_HERE} = $testdsn;
$ENV{WE_SET_THE_USER_HERE} = 'user';
$ENV{WE_SET_THE_PASS_HERE} = 'pass';

my $schema = test_dbic_schema_connect('TDSCTSchema',{
	env_user => 'WE_SET_THE_USER_HERE',
	env_pass => 'WE_SET_THE_PASS_HERE',
	env_dsn => 'WE_SET_THE_DSN_HERE',
}); 

ok(-f $testdb,'Testing for requested SQLite file');

isa_ok($schema,'TDSCTSchema');

is($schema->storage->connect_info->[0],$testdsn,'Testing if dsn of ENV reached DBIx::Class::Schema');
is($schema->storage->connect_info->[1],'user','Testing if user of ENV reached DBIx::Class::Schema');
is($schema->storage->connect_info->[2],'pass','Testing if pass of ENV reached DBIx::Class::Schema');

my $insert = $schema->resultset('TDSCT')->create({ id => 1 });

isa_ok($insert,'TDSCTSchema::Result::TDSCT');

done_testing;
