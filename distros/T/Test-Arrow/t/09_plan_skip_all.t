use Test::Arrow;

my $arr = Test::Arrow->new(
    plan => {
        skip_all => 'No Reason!',
    }
);

$arr->ok(1);

$arr->done_testing;
