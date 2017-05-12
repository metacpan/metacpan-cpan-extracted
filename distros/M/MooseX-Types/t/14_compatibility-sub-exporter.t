use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::Requires { 'Sub::Exporter' => '0' };
use lib 't/lib';

use SubExporterCompatibility qw(MyStr something);

ok MyStr->check('aaa'), "Correctly passed";
ok !MyStr->check([1]), "Correctly fails";
ok something(), "Found the something method";

done_testing;
