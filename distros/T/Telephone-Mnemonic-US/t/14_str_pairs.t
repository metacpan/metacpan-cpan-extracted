use Test::More  'no_plan';
use Telephone::Mnemonic::US::Math qw/ str_pairs /;

my $a =  [ [ '2', '628' ], [ '26', '28' ], [ '262', '8' ], [ '2628', '' ] ];

is_deeply str_pairs('2628'), $a;
is_deeply str_pairs('26'), [ [2,6], [26,'']];
is_deeply str_pairs('2'), [ [2,'']];
ok ! str_pairs('');
