use Test::Arrow;

my $arr = Test::Arrow->new;

{
    eval {
        Test::Arrow->new->got(1, 2);
    };

    $arr->ok(!!$@, $@);
}

{
    eval {
        Test::Arrow->new->expected(1, 2);
    };

    $arr->ok(!!$@, $@);
}

$arr->done_testing;
