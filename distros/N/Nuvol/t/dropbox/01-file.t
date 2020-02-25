use strict;

use Test::More;

use Nuvol::Test::File ':all';

my $package = 'Nuvol::Item';
my $service = 'Dropbox';

my $file = build_test_file $service;

ok my %dropbox_header = $file->_dropbox_header(mode => 'overwrite', path => '/Nuvol Testfile.txt'),
  'Get internal Dropbox header.';
ok my @request = $file->_upload_request, 'Get internal upload request';
my @expected = (
  'https://content.dropboxapi.com/2/files/upload',
  {%dropbox_header, 'Content-Type' => 'application/octet-stream'}
);
is_deeply \@request, \@expected, 'Request is correct';

test_basics $file, $service;

done_testing();
