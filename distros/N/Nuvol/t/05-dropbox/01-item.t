use strict;

use Test::More;

use Mojo::JSON 'from_json';
use Nuvol::Test::Item ':all';

my $package = 'Nuvol::Item';
my $service = 'Dropbox';

my $item = build_test_item $service;

ok my %dropbox_header = $item->_dropbox_header(abc=>'def'),
  'Get internal Dropbox header';
ok my $content = $dropbox_header{'Dropbox-API-Arg'}, 'Get content';
is_deeply from_json($content), {abc=>'def'},
  'Content is correct';

test_basics $item, $service;

my @testvalues = (
  {
    params   => {path => '/', type => 'Unknown'},
    realpath => '/',
    type     => 'Unknown',
    url      => 'files'
  },
  {
    params   => {path => '/Nuvol Testfolder', type => 'Unknown'},
    realpath => '/Nuvol%20Testfolder',
    type     => 'Unknown',
    url      => 'files',
  },
  {
    params   => {path => '/Nuvol Testfolder/Subfolder', type => 'Unknown'},
    realpath => '/Nuvol%20Testfolder/Subfolder',
    type     => 'Unknown',
    url      => 'files',
  },
  {
    params   => {path => '/Nuvol/Testfile.txt', type => 'Unknown'},
    realpath => '/Nuvol/Testfile.txt',
    type     => 'Unknown',
    url      => 'files'
  },
);

test_type $item, \@testvalues;
test_url $item,  \@testvalues;

done_testing();
