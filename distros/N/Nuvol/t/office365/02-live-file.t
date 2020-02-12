use strict;

use Test::More;
use Nuvol::Test::FileLive ':all';

my $service = 'Office365';

my $file = build_test_file $service;

ok my $parent_reference = $file->_parent_reference, 'Get internal parent reference';
ok $parent_reference->{driveId}, 'Parent reference contains a drive ID';

test_basics $file, $service;
test_crud $file,   $service;
test_copy $file,   $service;

done_testing();
