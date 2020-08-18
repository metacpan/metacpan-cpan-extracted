# © 2018, GoodData® Corporation

use strict;
use warnings;

use Net::Amazon::S3;
use Time::HiRes;

use Test::More;
use Test::Deep;

my $RETRY_TIME_SECONDS = 300; # 300 seconds = 5 minutes
my $RETRY_INTERVAL     = 0.5; # 0.5 = half a second

my $test_instance;
my $TEST_API;

use Net::Amazon::S3::Signature::V4;

package Test::API::S3;

sub new {
    my ($class, %params) = @_;

    bless [ $class->_s3( %params ) ], $class;
}

sub _authorization_method {
    $_[0][0]->authorization_method;
}

sub _s3 {
    my (undef, %params) = @_;

    Net::Amazon::S3->new(
        %params,
    );
}

sub _bucket {
    my ($self, $name) = @_;
    $self->[0]->bucket( $name );
}

sub _bucket_name {
    my (undef, $bucket) = @_;

    $bucket = $bucket->bucket if ref $bucket;
    $bucket;
}

sub _find_bucket_region {
    my ($self, $bucket) = @_;

    $bucket = $self->[0]->bucket( $bucket ) unless ref $bucket;

    $bucket->get_location_constraint;
}

sub _list_buckets {
    my ($self) = @_;

    my $buckets = $self->[0]->buckets;
    my $list = [ map $_->bucket, @{ $buckets->{buckets} } ];

    @$list;
}

sub _list_bucket {
    my ($self, $bucket) = @_;

    map $_->{key}, map @{ $_->{keys} }, $self->[0]->list_bucket_all({ bucket => $bucket });
}

sub _download_key {
    my (undef, $bucket, $key) = @_;

    $bucket->get_key( $key );
}

sub _sign_uri {
    my (undef, $bucket, $key, $expires_at) = @_;
    $expires_at //= time + $RETRY_TIME_SECONDS + 1;

    $bucket->query_string_authentication_uri( $key, $expires_at );
}

sub _add_key {
    my ($self, $bucket, $key, $value) = @_;

    $bucket->add_key( $key, $value, {} )
        || do { Test::More::diag( $self->[0]->errstr ); 0 }
}

sub _get_key {
    my (undef, $bucket, $key) = @_;

    $bucket->get_key( $key )->{value};
}

sub _delete_key {
    my (undef, $bucket, $key) = @_;
    $bucket->delete_key( $key );
}

sub _delete_multi_key {
    my (undef, $bucket, @keys) = @_;
    $bucket->delete_multi_object( @keys );
}

package Test::API::S3::Client;

sub new {
    my ($class, %params) = @_;

    bless [ $class->_s3( %params ) ], $class;
}

sub _authorization_method {
    $_[0][0]->s3->authorization_method;
}

sub _s3 {
    my (undef, %params) = @_;

    Net::Amazon::S3::Client->new(
        s3 => Net::Amazon::S3->new( %params )
    );
}

sub _bucket {
    my ($self, $name) = @_;
    $self->[0]->bucket( name => $name );
}

sub _bucket_name {
    my (undef, $bucket) = @_;

    $bucket = $bucket->name if ref $bucket;
    $bucket;
}

sub _find_bucket_region {
    my ($self, $bucket) = @_;

    $bucket = $self->[0]->bucket( $bucket ) unless ref $bucket;

    $bucket->location_constraint;
}

sub _list_buckets {
    my ($self) = @_;

    map $_->name, $self->[0]->buckets;
}

sub _list_bucket {
    my ($self, $bucket) = @_;

    my $stream = $bucket->list;
    my @list;
    push @list, $stream->items until $stream->is_done;
    map $_->key, @list;
}

sub _download_key {
    my (undef, $bucket, $key) = @_;

    $bucket->get_key( $key );
}

sub _sign_uri {
    my (undef, $bucket, $key, $expires_at) = @_;
    $expires_at //= time + $RETRY_TIME_SECONDS + 1;

    $bucket->object( key => $key, expires => $expires_at )->query_string_authentication_uri;
}

sub _add_key {
    my (undef, $bucket, $key, $value) = @_;

    eval {
        ref $value
            ? $bucket->object( key => $key )->put_filename( $$value )
            : $bucket->object( key => $key )->put( $value )
            ;
        1;
    } || do { Test::More::diag( $@ ); 0 }
}

sub _get_key {
    my (undef, $bucket, $key) = @_;

    $bucket->object( key => $key )->get;
}

sub _delete_key {
    my (undef, $bucket, $key) = @_;
    $bucket->object( key => $key )->delete;
}

sub _delete_multi_key {
    my (undef, $bucket, @keys) = @_;
    $bucket->delete_multi_object( @keys );
}

package main;

sub ok_read_after_write (&$$) {
    my ($read_code, $expect, $title) = @_;

    my $end_time = time + $RETRY_TIME_SECONDS;
    my $attempts = 0;

    my ($ok, $stack);

    while (1) {
        $attempts ++;

        last if $end_time < time;
        ($ok, $stack) = Test::Deep::cmp_details my $got = $read_code->(), $expect;
        last if $ok;

        diag "got: $got";
    };

    ok $ok, $title;

    unless ($ok) {
        diag "After $attempts attempts / $RETRY_TIME_SECONDS seconds";
        diag Test::Deep::deep_diag($stack);
    }

    $ok;
}

sub expect_bucket_is_listed {
    my (%params) = @_;

    my @list = $test_instance->_list_buckets;

    my $bucket = $params{bucket};
    $bucket = $test_instance->_bucket_name( $bucket );

    cmp_deeply $bucket, any( @list ), "bucket is listed in my buckets list";
}

sub expect_bucket_region {
    my (%params) = @_;

    my $got = $test_instance->_find_bucket_region( $params{bucket} );

    cmp_deeply $got, $params{region}, "bucket is in region $params{region}";
}

sub expect_upload_data_scalar {
    my (%params) = @_;

    ok $test_instance->_add_key( $params{bucket}, $params{key}, $params{content} ), $params{title} // 'upload data from scalar';
}

sub expect_upload_data_file {
    my (%params) = @_;

    ok $test_instance->_add_key( $params{bucket}, $params{key}, \$params{file} ), $params{title} // 'upload data from file';
}

sub expect_list_keys {
    my (%params) = @_;

    # Amazon S3 provides eventual consistency for read-after-write
    ok_read_after_write
        { [ $test_instance->_list_bucket( $params{bucket} ) ] }
        superbagof( @{ $params{keys} } ),
        $params{title} // 'list bucket keys',
        ;
}

sub expect_download_data {
    my (%params) = @_;

    ok_read_after_write
        { $test_instance->_get_key( $params{bucket}, $params{key} ) }
        $params{expect},
        $params{title} // 'download data',
        ;
}

sub expect_download_signed_uri {
    my (%params) = @_;

    my $uri = $test_instance->_sign_uri( $params{bucket}, $params{key} );
    diag "signed uri: $uri";
    my $ua = LWP::UserAgent->new;

    ok_read_after_write
        { $ua->get( $uri )->content }
        $params{expect},
        $params{title} // 'download signed uri',
        ;
}

sub expect_delete {
    my (%params) = @_;

    ok $test_instance->_delete_key( $params{bucket}, $params{key} ), $params{title} // 'delete one key';
}

sub expect_delete_multi {
    my (%params) = @_;

    ok $test_instance->_delete_multi_key( $params{bucket}, @{ $params{keys} } ), $params{title} // 'delete multiple keys';
}

sub works_with_bucket_test_suite {
    my %params = @_;

    $test_instance = $params{api}->new(
        aws_access_key_id     => 'AKIAJY2SOK27KAHEDDSA',
        aws_secret_access_key => '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',
        retry                 => 1,
        secure                => 1,
        use_virtual_host      => 1,
        (authorization_method  => $params{authorization_method}) x!! $params{authorization_method},
    );

    my $bucket = $test_instance->_bucket( $params{bucket} );
    my $key    = "Net-Amazon-S3/integration-$params{bucket}-$$";

    my $key_file    = "$key-file";
    my $key_scalar  = "$key-scalar";
    my $key_big     = "$key-big";

    my $file    = $0;
    my $content = "NET-AMAZON-S3/INTEGRATION"; #-$$";
    my $big     = '1234567890abcdef' x 1_000_000;

    subtest "$params{bucket} / $params{region} / $params{api} / $params{authorization_method}" => sub {
        diag "api ...... $params{api}";
        diag "bucket ... $params{bucket}";
        diag "region ... $params{region}";
        diag "auth ..... ${\ $test_instance->_authorization_method }";

        expect_bucket_is_listed     bucket => $bucket;
        expect_bucket_region        bucket => $bucket, region => $params{region};
        expect_upload_data_scalar   bucket => $bucket, key => $key_scalar, content => $content;
        expect_upload_data_scalar   bucket => $bucket, key => $key_big,    content => $big;
        expect_upload_data_file     bucket => $bucket, key => $key_file,   file    => $file;
        expect_list_keys            bucket => $bucket, keys => [ $key_scalar, $key_big, $key_file ];
        expect_list_keys            bucket => $bucket, keys => [ $key_scalar, $key_big ];
        expect_download_data        bucket => $bucket, key => $key_big, expect => $big;
        expect_download_data        bucket => $bucket, key => $key_scalar, expect => $content;
        expect_download_signed_uri  bucket => $bucket, key => $key_scalar, expect => $content;
        expect_delete               bucket => $bucket, key => $key_scalar;
        expect_delete_multi         bucket => $bucket, keys => [ $key_scalar, $key_big, $key_file ];
    };
}

# https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
my %region_with_signature_v2 = map +($_ => 1), (
    'ap-northeast-1',
    'ap-southeast-1',
    'ap-southeast-2',
    'eu-west-1',
    'sa-east-1',
    'us-east-1',
    'us-west-1',
    'us-west-2',
);

sub works_with_bucket {
    my (%params) = @_;

    for my $api (qw[ Test::API::S3::Client ]) {
    #for my $api (qw[ Test::API::S3 Test::API::S3::Client ]) {
        $params{api} = $api;

        works_with_bucket_test_suite authorization_method => 'Net::Amazon::S3::Signature::V2', %params
            if $region_with_signature_v2{$params{region}};

        works_with_bucket_test_suite authorization_method => 'Net::Amazon::S3::Signature::V4', %params;
    }
}

works_with_bucket
    bucket => 'gdc-dev-ca1-integration-tests',
    region => 'ca-central-1',
    ;

works_with_bucket
    bucket => 'gdc-dev-eu-integration-tests',
    region => 'eu-west-1',
    ;

works_with_bucket
    bucket => 'gdc-dev-us-east-1-integration-tests',
    region => 'us-east-1',
    ;

done_testing;
