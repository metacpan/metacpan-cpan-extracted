use Test::More;

use Rope::Handles::Hash;

my $data = Rope::Handles::Hash->new({a => 1, b => 2});

my $hash = { b => 4, c => 5 };

is($data->assign($hash)->get('b'), 4);

done_testing();
