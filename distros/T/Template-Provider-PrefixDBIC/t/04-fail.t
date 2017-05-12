use strict;
use warnings;

use Test::More tests => 4;
use Template::Provider::PrefixDBIC;

my $provider;

$provider = Template::Provider::PrefixDBIC->new({});
ok !defined($provider);
like(Template::Provider::PrefixDBIC->error,
    qr/You must provide a DBIx::Class::ResultSet/,
    "Attempting to create a Template::Provider::PrefixDBIC without a resultset should cause an error");

$provider = Template::Provider::PrefixDBIC->new({ SCHEMA => {} });
ok !defined($provider);
like(Template::Provider::PrefixDBIC->error,
    qr/does not support the SCHEMA option/,
    "Attemping to create a Template::Provider::PrefixDBIC with a schema should cause an error");
