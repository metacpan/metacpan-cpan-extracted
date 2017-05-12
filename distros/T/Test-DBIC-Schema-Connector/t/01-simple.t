use strict;
use warnings;
use Test::More;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::DBIC::Schema::Connector;
use TDSCTSchema;

ok(!defined $ENV{TDSCTSCHEMA_USER},'Testing for collide with existing ENV on user');
ok(!defined $ENV{TDSCTSCHEMA_PASS},'Testing for collide with existing ENV on pass');
ok(!defined $ENV{TDSCTSCHEMA_DSN},'Testing for collide with existing ENV on dsn');

my $schema = test_dbic_schema_connect('TDSCTSchema');

isa_ok($schema,'TDSCTSchema');

my $insert = $schema->resultset('TDSCT')->create({ id => 1 });

isa_ok($insert,'TDSCTSchema::Result::TDSCT');

done_testing;
