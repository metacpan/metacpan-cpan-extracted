use Test::More tests => 12;

use PGObject::Util::PGConfig;

my $config;
ok($config = PGObject::Util::PGConfig->new(), 'got a new config object');

$config->fromcontents("
 foo = bar # one option
 test = 'some value' # testing splitting
 local.test = 'some ''escaped'' value' #unescaping
 bar baz # space instead of =
 tested 'this isn''t invalid'
");

is(scalar $config->known_keys, 5, 'got 3 known keys');
is($config->get_value('foo'), 'bar', "Correct value for foo");
is($config->get_value('test'), 'some value', "correct value for test");
is($config->get_value('local.test'), "some 'escaped' value", 'Unescaping Works');
is($config->get_value('bar'), "baz", 'optional = omitted');
is($config->get_value('tested'), "this isn't invalid", 'mixed escaping');

$config->fromcontents("
   foo = '''foobar''' # with escaping
   test 'overwritten'");

is($config->get_value('foo'), "'foobar'", "Correct value for foo after re-run");
is($config->get_value('test'), 'overwritten', "correct value for test after rerun");
is($config->get_value('bar'), "baz", 'bar not overwritten');
is($config->get_value('tested'), "this isn't invalid", 'tested not overwritten');

is($config->filecontents(), 
"bar = 'baz'
foo = '''foobar'''
local.test = 'some ''escaped'' value'
test = 'overwritten'
tested = 'this isn''t invalid'"
, 'Correct output');

