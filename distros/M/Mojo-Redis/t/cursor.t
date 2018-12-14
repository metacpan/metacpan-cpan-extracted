use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

use constant ELEMENTS_COUNT => $ENV{REDIS_TEST_ELEMENTS_COUNT} || 1000;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db    = $redis->db;
my ($cursor, $expected, $guard, $res);

cleanup();

# Constructor
$cursor = $redis->cursor;
is_deeply $cursor->command, [scan => 0], 'default cursor command';
$cursor = $redis->cursor(scan => 0, match => '*', count => 100);
is_deeply $cursor->command, [scan => 0, match => '*', count => 100], 'scan, match and count';

note 'Reset cursor';
$cursor->command->[1] = 32;
$cursor->{finished} = 1;
$cursor->again;
is $cursor->command->[1], 0, 'cursor is reset';
ok !$cursor->finished, 'finished is reset';

$db->set("redis:scan_test:key$_", $_) for 1 .. ELEMENTS_COUNT;
$expected = [sort map {"redis:scan_test:key$_"} 1 .. ELEMENTS_COUNT];

note 'SCAN';
$cursor = $redis->cursor(scan => 0, match => 'redis:scan_test:key*');
$guard  = 10000;
$res    = [];
while ($guard-- && (my $r = $cursor->next)) { push @$res, @$r }
is_deeply [sort @$res], $expected, 'scan next() blocking';
ok $cursor->finished, 'finished is set';

$res = [];
$cursor->again->all(sub { Mojo::IOLoop->stop; $res = [$_[1], @{$_[2]}] });
Mojo::IOLoop->start;
is_deeply [sort @$res], ['', @$expected], 'all(CODE)';

$res = [];
$cursor->again->all_p->then(sub { $res = shift })->wait;
is_deeply [sort @$res], $expected, 'all_p()';

$cursor = $redis->cursor(keys => 'redis:scan_test:key*');
is_deeply [sort @{$cursor->all}], $expected, 'keys';

note 'HSCAN';
$db->hset('redis:scan_test:hash', "key.$_" => "val.$_") for 1 .. ELEMENTS_COUNT;
$cursor = $redis->cursor(hgetall => 'redis:scan_test:hash');
$cursor->next_p->then(sub { $res = $_[0] })->wait;
my @keys = keys %$res;
my @vals = values %$res;
like $keys[0], qr{^key\.\d+$}, 'hgetall next_p() keys';
like $vals[0], qr{^val\.\d+$}, 'hgetall next_p() vals';
is_deeply($cursor->all, $db->hgetall('redis:scan_test:hash'), 'hgetall');

$cursor = $redis->cursor(hkeys => 'redis:scan_test:hash');
is_deeply([sort @{$cursor->all}], [sort @{$db->hkeys('redis:scan_test:hash')}], 'hkeys');

note 'SSCAN';
$db->sadd('redis:scan_test:set', $_) for 1 .. ELEMENTS_COUNT;
$cursor = $redis->cursor(smembers => 'redis:scan_test:set');
is_deeply([sort @{$cursor->all}], [sort @{$db->smembers('redis:scan_test:set')}], 'smembers');

cleanup();
done_testing;

sub cleanup {
  $db->del("redis:scan_test:key$_", $_) for 1 .. ELEMENTS_COUNT;
  $db->del(qw(redis:scan_test:hash redis:scan_test:set redis:scan_test:zset));
}
