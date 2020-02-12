use strict;

use Test::More;

use Nuvol::Test::Drive ':all';

my $package = 'Nuvol::Drive';
my $service = 'Dummy';

my $drive = build_test_drive $service;

test_basics $drive, $service;

chomp(my $abc1234 = pack 'u', 'Abc1234');

my @urls = (
  [path     => '~'              => 'drives/Home'],
  [id       => $abc1234         => 'drives/Abc1234'],
  [metadata => {id => $abc1234} => 'drives/Abc1234'],
);
test_url $drive, \@urls;

done_testing();
