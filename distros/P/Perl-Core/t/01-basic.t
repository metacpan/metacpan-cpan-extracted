use Test::Modern;
use Perl::Core '5.14';

my $match = 5 |in| [10];
ok !$match, '|in| excluded successfully';
$match = 5 |in| [5,10];
ok $match, '|in| included successfully';

try {
    ok 5, '"try" executed successfully';
    print 1/0;
} catch($err) {
    ok $err, '"try" executed successfully';
} finally {
    ok 1, '"finally" executed successfully';
}

my $name = 'Bob';
my $age;
my $inches = 100;
my $pounds = 150;

my $person = {
    maybe name => $name,
    maybe age  => $age,
    provided $inches > 200, height => $inches,
    provided $pounds < 200, weight => $pounds,
};
cmp_deeply $person => {
    name   => $name,
    weight => $pounds,
}, '"maybe/provided" executed successfully';

define PI = 3.14;
is PI() => 3.14, '"define" executed successfully';

done_testing;
