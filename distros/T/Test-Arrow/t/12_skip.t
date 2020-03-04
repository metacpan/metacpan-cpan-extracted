use Test::Arrow;

my $arr = Test::Arrow->new;

SKIP: {
    $arr->skip("No Reason!", 1) if 1;

    $arr->ok(1);
    $arr->ok(2);
}

$arr->done_testing;
