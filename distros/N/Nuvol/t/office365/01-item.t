use strict;

use Test::More;

use Nuvol::Test::Item ':all';

my $package = 'Nuvol::Item';
my $service = 'Office365';

my $item = build_test_item $service;

test_basics $item, $service;

my @testvalues = (
  {
    params => {path => '/', type => 'Unknown'},
    type   => 'Unknown',
    url    => 'root'
  },
  {
    params => {path => 'NuvolTestfolder', type => 'Unknown'},
    type   => 'Unknown',
    url    => 'root:/NuvolTestfolder:',
  },
  {
    params => {path => 'NuvolTestfolder/Subfolder', type => 'Unknown'},
    type   => 'Unknown',
    url    => 'root:/NuvolTestfolder/Subfolder:',
  },
  {
    params => {path => 'Nuvol/Testfile.txt', type => 'Unknown'},
    type   => 'Unknown',
    url    => 'root:/Nuvol/Testfile.txt:'
  },
  {
    params => {id => 'Abc1234', type => 'Unknown'},
    type   => 'Unknown',
    url    => 'items/Abc1234'
  },
);

test_type $item, \@testvalues;
test_url $item,  \@testvalues;

done_testing();
