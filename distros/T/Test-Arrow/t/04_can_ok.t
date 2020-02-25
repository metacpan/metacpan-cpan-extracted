use Test::Arrow;

Test::Arrow->can_ok('Test::Arrow', 'ok');

Test::Arrow->new->can_ok('Test::Arrow', 'is');

Test::Arrow->can_ok('Test::Arrow', 'like', 'unlike');

Test::Arrow->done_testing;
