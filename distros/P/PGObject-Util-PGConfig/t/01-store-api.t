use Test::More tests => 8;

use PGObject::Util::PGConfig;

my $config;
ok($config = PGObject::Util::PGConfig->new(), 'Got new object');

ok((not defined $config->get_value('foo')), 'Undefined result with no key set');
$config->set('foo', 'bar');
is($config->get_value('foo'), 'bar', 'got right value back');
is(($config->known_keys)[0], 'foo', 'Got correct key back');
is(scalar $config->known_keys, 1, 'Got one key back');

$config->set('bar', 'baz');
is_deeply([sort $config->known_keys], [sort ('bar', 'foo')], 'correct list of keys back');

is($config->get_value('foo'), 'bar', 'foo is unchanged');
$config->set('foo', 'foobar');
is($config->get_value('foo'), 'foobar', 'foo changed on request');
