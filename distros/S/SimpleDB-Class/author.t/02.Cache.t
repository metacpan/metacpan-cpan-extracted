use Test::More tests => 14;
use Tie::IxHash;
use DateTime;
use lib ('../lib', 'lib');

my $a = {foo=>'A'};
my $b = {foo=>'B'};

use_ok('SimpleDB::Class::Cache');
my $cache = SimpleDB::Class::Cache->new(servers=>[{host=>'127.0.0.1',port=>11211}]);
isa_ok($cache, 'SimpleDB::Class::Cache');
$cache->set('foo',"a",$a);
is($cache->get('foo',"a")->{foo}, "A", "set/get");
$cache->set('foo',"b", $b);
my ($a1, $b1) = @{$cache->mget([['foo',"a"],['foo',"b"]])};
is($a1->{foo}, "A", "mget first value");
is($b1->{foo}, "B", "mget second value");
$cache->delete('foo',"a");
is(eval{$cache->get('foo',"a")}, undef, 'delete');
$cache->flush;
is(eval{$cache->get('foo',"b")}, undef, 'flush');

my $foo = {a=>'b', date=>DateTime->new(year=>2000, month=>5, day=>5, hour=>5, minute=>5, second=>5)};
$cache->set('foo','foo',$foo);
my $foo1 = $cache->get('foo','foo');
cmp_ok($foo->{date}, '==', $foo1->{date}, 'dates in are dates out');
is($foo1->{date}->year, 2000, 'year');
is($foo1->{date}->month, 5, 'month');
is($foo1->{date}->day, 5, 'day');
is($foo1->{date}->hour, 5, 'hour');
is($foo1->{date}->minute, 5, 'minute');
is($foo1->{date}->second, 5, 'second');
