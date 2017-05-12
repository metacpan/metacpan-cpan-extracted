
use strict;
use Test::Most;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::DBIx::Class
{
    schema_class => 'OpusVL::Preferences::Schema',
	traits       => 'Testpostgresql',
}, 'TestOwner';

my $schema = TestOwner->result_source->schema;
my $c = OpusVL::SimpleCrypto->GenerateKey;
$schema->encryption_key($c->key_string);
$schema->encryption_salt($c->deterministic_salt_string);

my $fields = TestOwner->prf_defaults;
ok $fields->create({ 
    name => 'pin',
    encrypted => 1,
    searchable => 0,
    default_value => '',
});
ok $fields->create({ 
    name => 'email',
    encrypted => 1,
    searchable => 1,
    default_value => '',
});
ok my $o = TestOwner->create({ name => 'test' });

$o->prf_set('pin' => '10013211');
$o->prf_set('email' => 'blackhole@opusvl.com');

is $o->prf_get('pin'), '10013211', 'Check we get the correct pin back';
is $o->prf_get('email'), 'blackhole@opusvl.com', 'Check we get the value back correctly';

# should be able to search by email, not pin.
ok my $results = TestOwner->with_fields({
    email => 'blackhole@opusvl.com',
});
is $results->count, 1;

# but partial searches should fail.
ok $results = TestOwner->with_fields({
    email => { -ilike => '%@opusvl.com' },
});
is $results->count, 0, 'Partial searches should fail on encrypted fields';

# but we'll kinda fudge it for a partial search of the exact value
ok $results = TestOwner->with_fields({
    email => { -ilike => '%blackhole@opusvl.com%' },
});
is $results->count, 1, 'Except when we could fudge it because you were entered the exact value';

ok $results = TestOwner->with_fields({
    pin => '10013211',
});
# FIXME: how should we let the dev know about this?
is $results->count, 0, 'Search by pin should return 0 results because not using searchable crypto';

eq_or_diff {
    email => 'blackhole@opusvl.com',
    pin => 10013211,
}, $o->safe_prefs_to_hash;


# FIXME: test unique fields.
# default values
# also auditing
done_testing;
