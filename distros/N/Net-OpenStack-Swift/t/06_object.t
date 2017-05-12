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

$sw->__dummy_response(eval get_data_section('put_container.headers.perl'), '{}');
my $headers = $sw->put_container(container_name => 'container_name1');
is $headers->{'content-length'}, 0;
is $headers->{'x-trans-id'}, 'txe924250e614142529f1b4-0055077df9';

done_testing;

__DATA__

@@ put_container.headers.perl
['content-length','0','x-trans-id','txe924250e614142529f1b4-0055077df9','content-type','text/html; charset=UTF-8','date','Tue, 17 Mar 2015 01:06:01 GMT']
