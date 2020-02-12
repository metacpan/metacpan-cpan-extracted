use strict;

use Test::More;

use Nuvol::Test::Drive ':all';

my $package = 'Nuvol::Drive';
my $service = 'Office365';

my $drive = build_test_drive $service;

test_basics $drive, $service;

my @urls = (
  [path     => '~'              => 'me/drive'],
  [id       => 'id1234'         => 'drives/id1234'],
  [metadata => {id => 'id1234'} => 'drives/id1234'],
);
test_url $drive, \@urls;

done_testing();
