use Test::Arrow;

my $arr = Test::Arrow->new;
$arr->throw(sub { Test::Arrow->import('wrong_arg') })->catch(qr/Wrong option: wrong_arg at/);

$arr->done_testing;
