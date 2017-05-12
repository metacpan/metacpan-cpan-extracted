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

my $schema = test_dbic_schema_connect('TDSCTSchema',{
	user => 'user',
	pass => 'pass',
	dsn => $testdsn,
}); 

ok(-f $testdb,'Testing for set SQLite file');

isa_ok($schema,'TDSCTSchema');

is($schema->storage->connect_info->[0],$testdsn,'Testing if fixed dsn reached DBIx::Class::Schema');
is($schema->storage->connect_info->[1],'user','Testing if fixed user reached DBIx::Class::Schema');
is($schema->storage->connect_info->[2],'pass','Testing if fixed pass reached DBIx::Class::Schema');

my $insert = $schema->resultset('TDSCT')->create({ id => 1 });

isa_ok($insert,'TDSCTSchema::Result::TDSCT');

done_testing;
