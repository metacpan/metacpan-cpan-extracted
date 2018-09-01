
use strict;
use warnings;

use Test::More tests => 1 + 15;
use Test::Warnings;

use Moose::Meta::Class;

use Net::Amazon::S3;

use Shared::Examples::Net::Amazon::S3::Request (
    qw[ expect_request_class ],
    qw[ expect_request_instance ],
);

my $request_class;

sub request_class {
    ($request_class) = @_;

    expect_request_class $request_class;
}

sub request_path {
    my ($title, %params) = @_;

    my $request = expect_request_instance
        request_class => $request_class,
        (with_bucket => $params{with_bucket}) x exists $params{with_bucket},
        (with_key => $params{with_key}) x exists $params{with_key},
        ;

    my $request_path = $request->_build_signed_request (
        method => 'GET',
        path => $request->_request_path,
    )->path;

    is
        $request_path,
        $params{expect},
        $title,
        ;
}

request_class 'Net::Amazon::S3::Request::Service';

request_path 'service request should return empty path',
    expect      => '',
    ;

request_class 'Net::Amazon::S3::Request::Bucket';

request_path 'bucket request',
    with_bucket => 'some-bucket',
    expect      => 'some-bucket/',
    ;

request_class 'Net::Amazon::S3::Request::Object';

request_path 'object request with empty key',
    with_bucket => 'some-bucket',
    with_key    => '',
    expect      => 'some-bucket/',
    ;

request_path 'object request should recognize leading slash',
    with_bucket => 'some-bucket',
    with_key    => '/some/key',
    expect      => 'some-bucket/some/key',
    ;

request_path 'object request should sanitize key with slash sequences',
    with_bucket => 'some-bucket',
    with_key    => '//some///key',
    expect      =>'some-bucket/some/key',
    ;

request_path 'object request should uri-escape key',
    with_bucket => 'some-bucket',
    with_key    => 'some/ %/key',
    expect      => 'some-bucket/some/%20%25/key',
    ;

