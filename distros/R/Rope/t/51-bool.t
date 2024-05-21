use Test::More;

use Rope::Handles::Bool;

my $data = Rope::Handles::Bool->new(0);

is($data->set, 1);

is($data->unset, 0);

is($data->toggle, 1);

is($data->not, '');

$data->unset;

is($data->not, 1);

done_testing();
