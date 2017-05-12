use strict;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::OpenStack::Swift;
use Data::Section::Simple qw( get_data_section );

my $sw = Net::OpenStack::Swift->new(
    auth_url     => 'https://objectstore-test.swift/v2.0',
    user         => '1234567',
    password     => 'abcdefg',
    tenant_name  => '1234567',
    #auth_version => '2.0',
);

# dummy token and url
$sw->token('abcdefg1234567');
$sw->storage_url('http://storage-url');

Test::MockObject::Extends->new($sw);
$sw->mock(__dummy_response => sub {
    my $self = shift;
    my ($headers, $content) = @_;
    $self->{__dummy_headers} = $headers;
    $self->{__dummy_content} = $content;
});

$sw->mock(_request => sub {
    my $self = shift;
    my %args = @_;

    my $mock_head = Test::MockObject->new;
    $mock_head->set_list('flatten', @{ $self->{__dummy_headers} });

    my $mock_res = Test::MockObject->new;
    $mock_res->set_true('is_success');
    $mock_res->set_always('status_line', 200);
    $mock_res->set_always('headers', $mock_head);
    $mock_res->set_always('content', $self->{__dummy_content});

    return $mock_res;
});

$sw->__dummy_response(eval get_data_section('get_account.headers.perl'), '{}');
my ($headers, $containers) = $sw->get_account(url => $sw->storage_url, token => $sw->token, marker => 'さいとう');
is $headers->{'x-account-container-count'}, 3;

done_testing;

__DATA__

@@ get_account.headers.perl
['date','Fri, 13 Mar 2015 10:07:55 GMT','accept-ranges','bytes','x-account-storage-policy-policy-0-bytes-used','1960344','content-length','2','x-account-meta-quota-bytes','110058536960000','x-timestamp','1421398525.11851','x-account-container-count','3','content-type','application/json; charset=utf-8','x-trans-id','txb1c3a2f4efe640faa7d8f-005502b6fb','x-account-bytes-used','1960344','x-account-object-count','4','x-account-storage-policy-policy-0-container-count','3','x-account-storage-policy-policy-0-object-count','4'] 
