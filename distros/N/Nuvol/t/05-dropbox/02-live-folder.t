use strict;

use Test::More;
use Nuvol::Test::FolderLive ':all';

my $service = 'Dropbox';

my $folder = build_test_folder $service;

test_basics $folder, $service;
test_cd $folder,     $service;

done_testing();
