use strict;
use warnings;
use Test::More tests => 10;

BEGIN { use_ok 'Parley::Schema' }

my ($schema, $resultset, $rs, $user_0, $user_0_roles, $status_ok);

# get a schema to query
$schema = Parley::Schema->connect(
    'dbi:Pg:dbname=parley'
);
isa_ok($schema, 'Parley::Schema');

# grab the Person resultset
$resultset = $schema->resultset('Person');
isa_ok($resultset, 'Parley::ResultSet::Person');

# we should be able to fetch user #0
$user_0 = $resultset->find(0);
isa_ok($user_0, 'Parley::Schema::Person');

# XXX (incorrect assumption - only in $c?)
# user_0 should have a "roles" method
can_ok($user_0, qw(roles));

# user_0 should have some roles
$user_0_roles = $user_0->roles;
isa_ok($user_0_roles, 'DBIx::Class::ResultSet');
ok($user_0_roles > 0, 'user 0 has at least one role');

# user_0 should be a site-admin
$status_ok = $user_0->check_user_roles('site_moderator');
is($status_ok, 1, 'user 0 is site_moderator');

# user 0 should NOT be a 'muppet'
$status_ok = $user_0->check_user_roles('muppet');
is($status_ok, 0, 'user 0 is NOT a muppet');

# user 0 should NOT be a site_moderator AND a 'muppet'
$status_ok = $user_0->check_user_roles('site_moderator', 'muppet');
is($status_ok, 0, 'user 0 is site_moderator but NOT a muppet');
