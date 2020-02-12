use strict;

use Test::More;
use Nuvol::Test::FolderLive ':all';

my $service = 'Office365';

my $folder = build_test_folder $service;

ok my $parent_reference = $folder->_parent_reference, 'Get internal parent reference';
ok $parent_reference->{driveId}, 'Parent reference contains a drive ID';

test_basics $folder, $service;
test_cd $folder,     $service;

done_testing();
