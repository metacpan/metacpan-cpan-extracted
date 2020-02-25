use strict;

use Test::More;

use Nuvol::Test::Folder ':all';

my $package = 'Nuvol::Item';
my $service = 'Dropbox';

my $folder = build_test_folder $service;

test_basics $folder, $service;

done_testing();
