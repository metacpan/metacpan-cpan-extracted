use strict;

use Test::More;
use Nuvol::Test::ConnectorLive ':all';
use Mojo::File 'path';

my $service = 'Dummy';

my $connector = build_test_connector $service;

test_basics $connector, $service;

# create dummy drives

my $testfolder = path($connector->configfile)->dirname->child('drives');
$testfolder->child('Home')->make_path;
$testfolder->child("Drive $_/")->make_path for 1 .. 3;

test_drivelist $connector;

done_testing();
