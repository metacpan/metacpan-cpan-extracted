use Test::More;

use Rope::Handles::Hash;

my $data = Rope::Handles::Hash->new({a => 1, b => 2});

is($data->delete('a')->length, 1);

done_testing();
