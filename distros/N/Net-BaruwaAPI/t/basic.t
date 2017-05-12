#!/usr/bin/env perl
use Test::More;
use Test::Fatal;
use warnings;
use strict;
use utf8;
use Net::BaruwaAPI;

diag( "Testing Net::BaruwaAPI Basic checks" );

my $do;

is(
    exception { $do = Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff', api_url => 'https://baruwa.example.com') },
    undef,
    '$do builds ok',
);

isa_ok( $do, 'Net::BaruwaAPI', '$do' );

like(
    exception { $do = Net::BaruwaAPI->new(api_token => 'xxxxxxxasasswqefdff') },
    qr/missing required arguments.*api_url/i,
    '$do complains about `api_url` not being set',
);

like(
    exception { $do = Net::BaruwaAPI->new(api_url => 'https://baruwa.example.com') },
    qr/missing required arguments.*api_token/i,
    '$do complains about `api_token` not being set',
);

my @methods = qw/
    get_users
    get_user
    create_user
    update_user
    delete_user
    set_user_passwd
    get_aliases
    create_alias
    update_alias
    delete_alias
    get_domains
    get_domain
    create_domain
    update_domain
    delete_domain
    get_domainaliases
    get_domainalias
    create_domainalias
    update_domainalias
    delete_domainalias
    get_deliveryservers
    get_deliveryserver
    create_deliveryserver
    update_deliveryserver
    delete_deliveryserver
    get_authservers
    get_authserver
    create_authserver
    update_authserver
    delete_authserver
    get_ldapsettings
    create_ldapsettings
    update_ldapsettings
    delete_ldapsettings
    get_radiussettings
    create_radiussettings
    update_radiussettings
    delete_radiussettings
    get_organizations
    get_organization
    create_organization
    update_organization
    delete_organization
    get_relay
    create_relay
    update_relay
    delete_relay
    get_status
/;

for (@methods) {
    ok( $do->can($_), '$do can ' . $_ );
}


done_testing;
