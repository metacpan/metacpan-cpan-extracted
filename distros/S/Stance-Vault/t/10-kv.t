#!perl
use strict;
use warnings;

use Test::More;
use Test::Deep;

use_ok 'Stance::Vault';

$ENV{PORT} = '9200';
$ENV{VAULT_TOKEN} = 'ichanhazcheezburger';

system('./t/setup');
is($?, 0, './t/setup should exit successfully (rc=0)');

my $vault = Stance::Vault->new("http://127.0.0.1:$ENV{PORT}");
ok(ref($vault), "Stance::Vault->new() creates and returns a vault ref");

ok(!$vault->kv_set('secret/handshake', { knock => 'knock' }),
	'unauthenticated kv_set() should fail');

$vault = $vault->authenticate(token => $ENV{VAULT_TOKEN});
ok(ref($vault), "\$vault->authenticate() returns an updated vault ref");

ok($vault->kv_set('secret/handshake', { knock => 'knock' }),
	'kv_set(secret/handshake, ...) should succeed')
	or diag explain $vault->last_error;

my $data = $vault->kv_get('secret/handshake');
ok($data, 'kv_get(secret/handshake) should succeed')
	or diag explain $vault->last_error;
cmp_deeply($data, superhashof({
	data => {
		data => {
			knock => 'knock',
		},
		metadata => ignore,
	},
})) or diag explain $data;

ok(!$vault->kv_get('e/no/ent'),
	'kv_get() fails for a non-existent path');

done_testing;
