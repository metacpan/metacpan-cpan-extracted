use strict;

use Test::More;

use Nuvol::Test::Drive ':all';

my $package = 'Nuvol::Drive';
my $service = 'Dropbox';

my $drive = build_test_drive $service;

test_basics $drive, $service;

done_testing();
