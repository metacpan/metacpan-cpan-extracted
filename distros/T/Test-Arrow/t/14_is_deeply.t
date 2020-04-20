use Test::Arrow;

my $arr = Test::Arrow->new;

$arr->got(123)->expected(123)->is_deeply;

$arr->got([])->expected([])->is_deeply;

$arr->got([1])->expected([1])->is_deeply;

$arr->got([1, 2])->expected([1, 2])->is_deeply;

$arr->got({})->expected({})->is_deeply;

$arr->got({foo => 2})->expected({foo => 2})->is_deeply;

$arr->got([1, {foo => 3}])->expected([1, {foo => 3}])->is_deeply;

$arr->is_deeply([1,2,3], [1,2,3], 'is_deeply');

Test::Arrow->done_testing;
