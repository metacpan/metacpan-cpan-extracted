use strict;
use Test::More;
use Test::MockObject::Extends;
use Net::OpenStack::Swift::InnerKeystone;

my $ksclient = Net::OpenStack::Swift::InnerKeystone::V2_0->new(
    auth_url     => 'https://objectstore-test.swift/v2.0',
    user         => '1234567',
    password     => 'abcdefg',
    tenant_name  => '1234567',
);

is $ksclient->auth_url, 'https://objectstore-test.swift/v2.0';
is $ksclient->user, '1234567';
is $ksclient->password, 'abcdefg';
is $ksclient->tenant_name, '1234567';
is $ksclient->auth_token, undef;
is $ksclient->service_catalog, undef;

Test::MockObject::Extends->new($ksclient);
$ksclient->mock(auth => sub {
    my $self = shift;
    my $body_params = JSON::from_json(<DATA>);
    $self->auth_token($body_params->{access}->{token}->{id});
    $self->service_catalog($body_params->{access}->{serviceCatalog});
    return $self->auth_token();
});

is $ksclient->auth(), '5c88892c8f754e8b9a0929ddd6f064d6';
is $ksclient->auth_token(), '5c88892c8f754e8b9a0929ddd6f064d6';
is $ksclient->service_catalog()->[0]->{endpoints}->[0]->{id}, '36e5d17a69864a4f8ec51b6598648141';

my $endpoint = $ksclient->service_catalog_url_for(service_type=>'object-store', endpoint_type=>'publicURL');
is $endpoint, 'https://objectstore-test.swift/v1/e4cf2219a08a42ccac78d2e2b03bc896';

done_testing;

__DATA__
{"access":{"token":{"issued_at":"2015-03-12T08:14:58.869220","expires":"2015-03-13T08:14:58Z","id":"5c88892c8f754e8b9a0929ddd6f064d6","tenant":{"description":"1234567","enabled":true,"id":"e4cf2219a08a42ccac78d2e2b03bc896","name":"1234567"}},"user":{"id":"64e75ae5e02d41b88f50e3c364f7b032","name":"1234567"},"serviceCatalog":[{"endpoints":[{"id":"36e5d17a69864a4f8ec51b6598648141","adminURL":"","internalURL":"https://objectstore-test.swift/v1/e4cf2219a08a42ccac78d2e2b03bc896","publicURL":"https://objectstore-test.swift/v1/e4cf2219a08a42ccac78d2e2b03bc896","region":"RegionOne"}],"endpoints_links":[],"type":"object-store","name":"swift"},{"endpoints":[{"id":"2e6529987dd14de0a7a8158dbc3ac747","adminURL":"","internalURL":"https://objectstore-test.swift/v2.0","publicURL":"https://objectstore-test.swift/v2.0","region":"RegionOne"}],"endpoints_links":[],"type":"identity","name":"keystone"}]}}
