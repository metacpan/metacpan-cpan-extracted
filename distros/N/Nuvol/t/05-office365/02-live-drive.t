use strict;

use Test::More;
use Nuvol::Test::DriveLive ':all';
use Mojo::File 'path';

my $service = 'Office365';

my $drive = build_test_drive $service;

test_basics $drive, $service;

done_testing();
