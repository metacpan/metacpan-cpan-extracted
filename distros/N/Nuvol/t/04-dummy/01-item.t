use strict;

use Test::More;

use Nuvol::Test::Item ':all';

my $package = 'Nuvol::Item';
my $service = 'Dummy';

my $item = build_test_item $service;

test_basics $item, $service;

my @testvalues = (
  {
    params   => {path => '/', type => 'Unknown'},
    realpath => '/',
    type     => 'Unknown',
    url      => '',
  },
  {
    params   => {path => '/Nuvol Testfolder', type => 'Unknown'},
    realpath => '/Nuvol%20Testfolder',
    type     => 'Unknown',
    url      => 'Nuvol%20Testfolder',
  },
  {
    params   => {path => '/Nuvol Testfolder/Subfolder', type => 'Unknown'},
    realpath => '/Nuvol%20Testfolder/Subfolder',
    type     => 'Unknown',
    url      => 'Nuvol%20Testfolder/Subfolder',
  },
  {
    params   => {path => '/Nuvol/Testfile.txt', type => 'Unknown'},
    realpath => '/Nuvol/Testfile.txt',
    type     => 'Unknown',
    url      => 'Nuvol/Testfile.txt',
  },
);

test_type $item, \@testvalues;
test_url $item,  \@testvalues;

done_testing();
