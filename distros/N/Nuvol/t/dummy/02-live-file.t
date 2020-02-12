use strict;

use Test::More;
use Nuvol::Test::FileLive ':all';

my $service = 'Dummy';

my $file = build_test_file $service;

test_basics $file, $service;
test_crud $file,   $service;
test_copy $file,   $service;

done_testing();
