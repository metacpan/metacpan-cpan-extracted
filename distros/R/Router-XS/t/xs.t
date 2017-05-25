use strict;
use warnings;
use Test::More;
use Test::Fatal;

sub test { 'test' }
sub home { 'home' }
sub wild { 'wild' }

sub test_crud { @_ == 3 }

BEGIN { use_ok 'Router::XS', ':all' }

ok !defined add_route('GET/home/foo/', \&test), 'add route succeeds on undef';
is ref [check_route('GET/home/foo/')]->[0], 'CODE', 'returns the coderef';
is ref [check_route('GET/home/foo')]->[0], 'CODE', 'path missing trailing slash matches';
is [check_route('GET/home/foo')]->[0](), 'test', 'correct coderef is returned';
ok !defined check_route('POST/'), 'missing route returns null';
ok !defined check_route('GET'), 'partial match route returns null';
ok !defined check_route('GET/'), 'partial match route returns null';
ok !defined check_route('GET/home'), 'partial match route returns null';

### wildcard routes
ok !defined add_route('*/', \&home), 'add missing route';
is [check_route('POST')]->[0](), 'home', 'route is now found';
is [check_route('PUT/')]->[0](), 'home', 'route is found with trailing slash';

my $wild_ref = \&wild;
ok !defined add_route('*/*', $wild_ref), 'add wildcard route';
is_deeply [check_route('POST/foo')], [$wild_ref, 'foo'], 'coderef and capture are returned';

my $test_crud_ref = \&test_crud;
ok !defined add_route('PUT/home/*/*/*', $test_crud_ref), 'add wildcard route';
is_deeply [check_route('PUT/home/user/update/name')], [$test_crud_ref, qw(user update name)], 'wildcard route is found';
ok !check_route('PUT/home/user/update'), 'missing wildcard route returns undef';

get '/foo/bar' => sub { 'getfoobar' };
is [check_route('GET/foo/bar')]->[0](), 'getfoobar';

post '/foo/bar' => sub { 'postfoobar' };
is [check_route('POST/foo/bar')]->[0](), 'postfoobar';

put '/foo/bar' => sub { 'putfoobar' };
is [check_route('PUT/foo/bar')]->[0](), 'putfoobar';

options '/foo/bar' => sub { 'optionsfoobar' };
is [check_route('OPTIONS/foo/bar')]->[0](), 'optionsfoobar';

head '/foo/bar' => sub { 'headfoobar' };
is [check_route('HEAD/foo/bar')]->[0](), 'headfoobar';

del '/foo/bar' => sub { 'delfoobar' };
is [check_route('DELETE/foo/bar')]->[0](), 'delfoobar';

conn '/foo/bar' => sub { 'connfoobar' };
is [check_route('CONNECT/foo/bar')]->[0](), 'connfoobar';

patch '/foo/bar' => sub { 'patchfoobar' };
is [check_route('PATCH/foo/bar')]->[0](), 'patchfoobar';

any '/bar/foo' => sub { 'anybarfoo' };
is [check_route('GET/bar/foo')]->[0](), 'anybarfoo';

# check invalid args die appropriately
ok exception { check_route() };
ok exception { check_route(undef) };
ok exception { check_route('') };
ok exception { add_route() };
ok exception { add_route(undef) };
ok exception { add_route('') };
ok exception { add_route('','') };
ok exception { add_route('/') };
ok exception { add_route('/', undef) };

done_testing;
