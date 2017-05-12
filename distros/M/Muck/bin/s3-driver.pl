#!/usr/bin/perl

#  This software code is made available "AS IS" without warranties of any
#  kind.  You may copy, display, modify and redistribute the software
#  code either by itself or as incorporated into your code; provided that
#  you do not remove any proprietary notices.  Your use of this software
#  code is at your own risk and you waive any claim against Amazon
#  Digital Services, Inc. or its affiliates with respect to your use of
#  this software code. (c) 2006 Amazon Digital Services, Inc. or its
#  affiliates.

use strict;
use warnings;

use Muck::FS::S3::AWSAuthConnection;
use Muck::FS::S3::QueryStringAuthGenerator;
use HTTP::Date;
use Data::Dumper;

my $AWS_ACCESS_KEY_ID = 'your aws id';
my $AWS_SECRET_ACCESS_KEY = 'your aws sect';

my $conn = Muck::FS::S3::AWSAuthConnection->new($AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY);

my $BUCKET_NAME = "$AWS_ACCESS_KEY_ID-test-bucket";
my $KEY_NAME = 'test-key';

print "----- creating bucket -----\n";
print $conn->create_bucket($BUCKET_NAME)->http_response->message, "\n";

print "----- listing bucket -----\n";
print join(', ', map { $_->{Key} } @{$conn->list_bucket($BUCKET_NAME)->entries}), "\n";

print "----- putting object -----\n";
print $conn->put(
    $BUCKET_NAME,
    $KEY_NAME,
    Muck::FS::S3::S3Object->new('this is a test'),
    { 'Content-Type' => 'text/plain' }
)->http_response->message, "\n";

print "----- getting object -----\n";
print $conn->get($BUCKET_NAME, $KEY_NAME)->object->data, "\n";

print "----- listing bucket -----\n";
print join(', ', map { $_->{Key} } @{$conn->list_bucket($BUCKET_NAME)->entries}), "\n";


print "----- query string auth example -----\n";
my $generator = Muck::FS::S3::QueryStringAuthGenerator->new($AWS_ACCESS_KEY_ID, $AWS_SECRET_ACCESS_KEY, 0);
$generator->expires_in(60);
print "\nTry this url out in your browser (it will only be valid for 60 seconds).\n\n";
my $url = $generator->get($BUCKET_NAME, $KEY_NAME);
print "$url\n";
print "\npress enter> ";
getc;

print "\nNow try just the url without the query string arguments.  it should fail.\n\n";
print substr($url, 0, index($url, '?')), "\n";
print "\npress enter> ";
getc;


print "----- putting object with metadata and public read acl -----\n";
print $conn->put(
    $BUCKET_NAME,
    "$KEY_NAME-public",
    Muck::FS::S3::S3Object->new('this is a publicly readable test', { blah => 'foo' }),
    { 'x-amz-acl' => 'public-read', 'Content-Type' => 'text-plain' }
)->http_response->message, "\n";


print "----- anonymous read test ----\n";
print "\nYou should be able to try this in your browser\n\n";
my $public_url = $generator->get($BUCKET_NAME, "$KEY_NAME-public");
print substr($public_url, 0, index($public_url, "?")), "\n";
print "\npress enter> ";
getc;

print "----- getting object's acl -----\n";
print $conn->get_acl($BUCKET_NAME, $KEY_NAME)->object->data, "\n";

print "----- deleting objects -----\n";
print $conn->delete($BUCKET_NAME, $KEY_NAME)->http_response->message, "\n";
print $conn->delete($BUCKET_NAME, "$KEY_NAME-public")->http_response->message, "\n";

print "----- listing bucket -----\n";
print join(', ', map { $_->{Key} } @{$conn->list_bucket($BUCKET_NAME)->entries}), "\n";

print "----- listing all my buckets -----\n";
print join(', ', map { $_->{Name} } @{$conn->list_all_my_buckets()->entries}), "\n";

print "----- deleting bucket -----\n";
print $conn->delete_bucket($BUCKET_NAME)->http_response->message, "\n";
