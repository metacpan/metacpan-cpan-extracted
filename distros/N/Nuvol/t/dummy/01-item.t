use strict;

use Test::More;

use Nuvol::Test::Item ':all';

my $package = 'Nuvol::Item';
my $service = 'Dummy';

my $item = build_test_item $service;

test_basics $item, $service;

my @testvalues = (
  {
    params => {path => '/', type => 'Unknown'},
    type   => 'Unknown',
    url    => '',
  },
  {
    params => {path => 'NuvolTestfolder', type => 'Unknown'},
    type   => 'Unknown',
    url    => 'NuvolTestfolder',
  },
  {
    params => {path => 'NuvolTestfolder/Subfolder', type => 'Unknown'},
    type   => 'Unknown',
    url    => 'NuvolTestfolder/Subfolder',
  },
  {
    params => {path => 'Nuvol/Testfile.txt', type => 'Unknown'},
    type   => 'Unknown',
    url    => 'Nuvol/Testfile.txt',
  },
);

test_type $item, \@testvalues;
test_url $item,  \@testvalues;

done_testing();
