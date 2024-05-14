use Test::More;

use Rope::Handles::Hash;

my $data = Rope::Handles::Hash->new({a => 1, b => 2});

is_deeply([$data->keys], [qw/a b/]);

is_deeply([$data->values], [qw/1 2/]);

done_testing();
