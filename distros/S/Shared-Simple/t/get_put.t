use strict;
use warnings;

use Test::More tests => 20;

BEGIN { use_ok('Shared::Simple') }

my $obj = Shared::Simple->new('testshm_getput', Shared::Simple::EXCLUSIVE);

# get on missing key returns undef
ok(!defined $obj->get('nosuchkey'), 'get returns undef for missing key');

# put succeeds and returns true
ok($obj->put('hello', 'world'), 'put returns true for valid key/value');

# get returns the stored value
is($obj->get('hello'), 'world', 'get returns the stored string value');

# put same key again overwrites
ok($obj->put('hello', 'updated'), 'put same key twice does not croak');
is($obj->get('hello'), 'updated', 'get returns overwritten value');

# exact 32-byte value is accepted
ok($obj->put('maxkey', 'x' x 32), 'put accepts value of exactly 32 bytes');

# input validation — key
eval { $obj->put('', 'val') };
like($@, qr/key must not be empty/, 'put croaks on empty key');

eval { $obj->put(undef, 'val') };
like($@, qr/key must be defined/, 'put croaks on undef key');

eval { $obj->get('') };
like($@, qr/key must not be empty/, 'get croaks on empty key');

eval { $obj->get(undef) };
like($@, qr/key must be defined/, 'get croaks on undef key');

# input validation — value
eval { $obj->put('k', '') };
like($@, qr/value must not be empty/, 'put croaks on empty value');

eval { $obj->put('k', 'x' x 33) };
like($@, qr/value must not exceed 32 bytes/, 'put croaks on value over 32 bytes');

# get_size
is($obj->get_size, 2, 'get_size returns correct pair count');
$obj->put('another', 'val');
is($obj->get_size, 3, 'get_size increments after put');

# get_all
my $all = $obj->get_all;
ok(ref($all) eq 'HASH',       'get_all returns a hashref');
is($all->{hello},   'updated', 'get_all contains correct value for hello');
is($all->{maxkey},  'x' x 32, 'get_all contains correct value for maxkey');
is($all->{another}, 'val',     'get_all contains correct value for another');
is(scalar keys %$all, 3,       'get_all hashref has correct number of keys');
