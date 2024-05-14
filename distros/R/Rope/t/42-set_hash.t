use Test::More;

use Rope::Handles::Hash;

my $data = Rope::Handles::Hash->new(a => 1, b => 2);

is($data->get('a'), 1);

is($data->set('a', 3)->get('a'), 3);

done_testing();
