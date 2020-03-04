use Test::Arrow;

my $arr = Test::Arrow->new(
    plan => {
        tests => 2,
    }
);

$arr->ok(1);
$arr->ok(2);
