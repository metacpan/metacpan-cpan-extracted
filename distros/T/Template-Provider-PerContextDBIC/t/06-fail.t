use strict;
use warnings;

use Test::More tests => 2;
use Template::Provider::PerContextDBIC;

my $provider;

$provider = Template::Provider::PerContextDBIC->new({ SCHEMA => {} });
ok !defined($provider);
like(Template::Provider::PerContextDBIC->error,
    qr/does not support the SCHEMA option/,
    "Attemping to create a Template::Provider::PerContextDBIC with a schema should cause an error");
