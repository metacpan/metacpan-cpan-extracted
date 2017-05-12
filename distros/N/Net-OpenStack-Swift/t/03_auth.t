use strict;
use Test::More;
use Test::MockObject::Extends;
use Net::OpenStack::Swift;

my $sw = Net::OpenStack::Swift->new(
    auth_url     => 'https://objectstore-test.swift/v2.0',
    user         => '1234567',
    password     => 'abcdefg',
    tenant_name  => '1234567',
    #auth_version => '2.0',
);

is $sw->auth_version, '2.0';
is $sw->auth_url, 'https://objectstore-test.swift/v2.0';
is $sw->user, '1234567';
is $sw->password, 'abcdefg';
is $sw->tenant_name, '1234567';
is $sw->token, undef;
is $sw->storage_url, undef;


Test::MockObject::Extends->new($sw);
$sw->mock(auth_keystone => sub {
    my $self = shift;
    # dummy token and storage url
    $self->token('abcdefg1234567');
    $self->storage_url('http://storage-url');
});


my ($storage_url, $token) = $sw->get_auth();
is $storage_url, 'http://storage-url';
is $token, 'abcdefg1234567';

done_testing;
