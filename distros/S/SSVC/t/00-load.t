#!perl

use strict;
use warnings;

use Test::More;

use_ok('SSVC');
use_ok('SSVC::CISA');
use_ok('SSVC::CoordinatorPublication');
use_ok('SSVC::CoordinatorTriage');
use_ok('SSVC::Deployer');

done_testing();

diag("SSVC $SSVC::VERSION, Perl $], $^X");
