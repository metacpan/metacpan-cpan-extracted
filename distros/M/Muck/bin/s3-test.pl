#!/usr/bin/perl

# This software code is made available "AS IS" without warranties of any        
# kind.  You may copy, display, modify and redistribute the software            
# code either by itself or as incorporated into your code; provided that        
# you do not remove any proprietary notices.  Your use of this software         
# code is at your own risk and you waive any claim against Amazon               
# Digital Services, Inc. or its affiliates with respect to your use of          
# this software code. (c) 2006 Amazon Digital Services, Inc. or its             
# affiliates.          

use strict;
use warnings;

use Test::More qw/no_plan/;

use Muck::FS::S3::AWSAuthConnection;
use Muck::FS::S3::QueryStringAuthGenerator;

my $AWS_ACCESS_KEY_ID = 'your aws id';
my $AWS_SECRET_ACCESS_KEY = 'your aws secret';

my $BUCKET_NAME = "$AWS_ACCESS_KEY_ID-test-bucket";

my $conn =
    Muck::FS::S3::AWSAuthConnection->new($AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY);

my $response = $conn->create_bucket($BUCKET_NAME);
is($response->http_response->code, 200, 'create bucket');

$response = $conn->list_bucket($BUCKET_NAME);
is($response->http_response->code, 200, 'list bucket ');
is(scalar @{$response->entries}, 0, 'bucket is empty');

my $text = 'this is a test';
my $key = 'example.txt';
my $inner_key = 'test/inner.txt';
my $last_key = 'z-last-key.txt';

$response = $conn->put($BUCKET_NAME, $key, $text);
is($response->http_response->code, 200, 'put with string argument');

$response =
    $conn->put(
        $BUCKET_NAME,
        $key,
        Muck::FS::S3::S3Object->new($text, {title => 'title'}),
        {'Content-Type' => 'text/plain'});

is($response->http_response->code, 200, 'put with complex argument and headers');

$response = $conn->get($BUCKET_NAME, $key);
is($response->http_response->code, 200, 'get object');
is($response->object->data, $text, 'got right data');
eq_hash($response->object->metadata, {title => 'title'}, "metadata is correct");
is($response->http_response->header('Content-Length'), length($text), "got content-length header");

my $title_with_spaces = " \t   title with leading and trailing spaces     ";
$response =
    $conn->put(
        $BUCKET_NAME,
        $key,
        Muck::FS::S3::S3Object->new($text, {title => $title_with_spaces}),
        {'Content-Type' => 'text/plain'});

is($response->http_response->code, 200, 'put with headers with leading and trailing spaces');

$response = $conn->get($BUCKET_NAME, $key);
is($response->http_response->code, 200, 'get object');
eq_hash(
    $response->object->metadata,
    {title => $title_with_spaces},
    "metadata with spaces is correct"
);

# delimited list tests
$response = $conn->put($BUCKET_NAME, $inner_key, $text);
is($response->http_response->code, 200, 'put with string argument');

$response = $conn->put($BUCKET_NAME, $last_key, $text);
is($response->http_response->code, 200, 'put with string argument');

$response = do_delimited_list($BUCKET_NAME, '', { delimiter => '/' }, 2, 1, 'root directory');

$response = do_delimited_list($BUCKET_NAME, 1, { 'max-keys' => 1, delimiter => '/' }, 1, 0, 'root directory with max-keys=1', 'example.txt');

$response = do_delimited_list($BUCKET_NAME, 1, { 'max-keys' => 2, delimiter => '/' }, 1, 1, 'root directory with max-keys=2, page 1', 'test/');

my $marker = $response->next_marker;

$response = do_delimited_list($BUCKET_NAME, '', { marker => $marker, 'max-keys' => 2, delimiter => '/' }, 1, 0, 'root directory with max-keys=2, page 2');

$response = do_delimited_list($BUCKET_NAME, '', { delimiter => '/', prefix => 'test/' }, 1, 0, 'test/ directory');

$response = $conn->delete($BUCKET_NAME, $inner_key);
is($response->http_response->code, 204, "delete $inner_key");
$response = $conn->delete($BUCKET_NAME, $last_key);
is($response->http_response->code, 204, "delete $last_key");
# end delimited tests

my $weird_key = "&=//%# ++++";
$response = $conn->put($BUCKET_NAME, $weird_key, $text);
is($response->http_response->code, 200, "put weird key");

$response = $conn->get($BUCKET_NAME, $weird_key);
is($response->http_response->code, 200, "get weird key");

$response = $conn->get_acl($BUCKET_NAME, $key);
is($response->http_response->code, 200, "get acl");

my $acl = $response->object->data;

$response = $conn->put_acl($BUCKET_NAME, $key, $acl);
is($response->http_response->code, 200, "put acl");

$response = $conn->get_bucket_acl($BUCKET_NAME);
is($response->http_response->code, 200, "get bucket acl");

my $bucket_acl = $response->object->data;

$response = $conn->put_bucket_acl($BUCKET_NAME, $bucket_acl);
is($response->http_response->code, 200, "put bucket acl");

$response = $conn->list_bucket($BUCKET_NAME);
is($response->http_response->code, 200, "list bucket");
my @entries = @{$response->entries};
is(scalar @entries, 2, "got back the right number of keys");
# depends on $weird_key < $key
is($entries[0]->{Key}, $weird_key, "first key is right");
is($entries[1]->{Key}, $key, "second key is right");

$response = $conn->list_bucket($BUCKET_NAME, {'max-keys' => 1});
is($response->http_response->code, 200, "list bucket with args");
my @maxed_entries = @{$response->entries};
is(scalar @maxed_entries, 1, "got back the right number of keys");

foreach my $entry (@entries) {
    $response = $conn->delete($BUCKET_NAME, $entry->{Key});
    is($response->http_response->code, 204, "delete $entry->{Key}");
}

$response = $conn->get_bucket_logging($BUCKET_NAME);
is($response->http_response->code, 200, "get logging");

my $bucket_logging = $response->object->data;

$response = $conn->put_bucket_logging($BUCKET_NAME, $bucket_logging);
is($response->http_response->code, 200, "put bucket logging");

$response = $conn->list_all_my_buckets;
is($response->http_response->code, 200, "list all my buckets");
my @buckets = @{$response->entries};

$response = $conn->delete_bucket($BUCKET_NAME);
is($response->http_response->code, 204, "delete bucket");

$response = $conn->list_all_my_buckets;
is($response->http_response->code, 200, "list all my buckets again");
is(scalar @{$response->entries}, scalar @buckets - 1, "bucket count is correct");

sub verify_list_bucket_response {
    my ($response, $bucket, $is_truncated, $parameters, $next_marker) = @_;
    # default parameter values, these will always be echoed back despite being unspecified
    is($bucket, $response->name);
    is($parameters->{prefix}, $response->prefix);
    is($parameters->{marker}, $response->marker);
    if ($parameters->{'max-keys'}) {
        is($parameters->{'max-keys'}, $response->max_keys);
    }
    is($parameters->{delimiter}, $response->delimiter);
    is($is_truncated, $response->is_truncated);
    is($next_marker, $response->next_marker);
}

sub do_delimited_list {
    
    my ($bucket_name, $is_truncated, $parameters, $regular_expected, $common_expected, $test_name, $next_marker) = @_;
    
    $response = $conn->list_bucket($bucket_name, $parameters);
    is($response->http_response->code, 200, $test_name);
    is(scalar @{$response->entries}, $regular_expected, "right number of regular entries");
    is(scalar @{$response->common_prefixes}, $common_expected, "right number of common prefixes");
    verify_list_bucket_response($response, $bucket_name, $is_truncated, $parameters, $next_marker);

    return $response;
}

my $generator =
    Muck::FS::S3::QueryStringAuthGenerator->new($AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY);

sub check_url {
    my ($url, $method, $code, $message, $data) = @_;
    $data ||= '';
    my $agent = LWP::UserAgent->new();
    my $request = HTTP::Request->new($method, $url);
    if ($method eq 'PUT') {
        $request->content($data);
        $request->header('Content-Length', length $data);
    }
    my $response = $agent->request($request);
    is($response->code, $code, $message);
}

check_url($generator->create_bucket($BUCKET_NAME), "PUT", 200, "create bucket");
check_url($generator->put($BUCKET_NAME, $key, ''), "PUT", 200, "put object", "test data");
check_url($generator->get($BUCKET_NAME, $key), "GET", 200, "get object");
check_url($generator->list_bucket($BUCKET_NAME), "GET", 200, "list bucket");
check_url($generator->list_all_my_buckets, "GET", 200, "list all my buckets");
check_url($generator->get_bucket_logging($BUCKET_NAME), "GET", 200, "get bucket logging");
check_url($generator->put_bucket_logging($BUCKET_NAME, $bucket_logging), "PUT", 200, "put bucket logging", $bucket_logging);
check_url($generator->get_acl($BUCKET_NAME, $key), "GET", 200, "get acl");
check_url($generator->put_acl($BUCKET_NAME, $key, $acl), "PUT", 200, "put acl", $acl);
check_url($generator->get_bucket_acl($BUCKET_NAME), "GET", 200, "get bucket acl");
check_url($generator->put_bucket_acl($BUCKET_NAME, $bucket_acl), "PUT", 200, "put bucket acl", $bucket_acl);
check_url($generator->delete($BUCKET_NAME, $key), "DELETE", 204, "delete object");
check_url($generator->delete_bucket($BUCKET_NAME), "DELETE", 204, "delete bucket");
