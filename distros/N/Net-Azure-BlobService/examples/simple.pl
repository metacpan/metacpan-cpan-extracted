#!/home/acme/Public/perl-5.14.2/bin/perl
use strict;
use warnings;
use lib 'lib';
use 5.14.0;
use HTTP::Request;
use HTTP::Request::Common qw(GET HEAD PUT DELETE);
use Net::Azure::BlobService;
use URI::QueryParam;
use XML::LibXML;

my $account = 'astray';

my $primary_access_key
    = 'XXX';

my $blobservice = Net::Azure::BlobService->new(
    primary_access_key => $primary_access_key );

# Get Blob Service Properties
my $uri = URI->new("https://$account.blob.core.windows.net/");
$uri->query_form( [ restype => 'service', comp => 'properties' ] );
my $request = GET $uri;

# Create Container
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer");
# $uri->query_form( [ restype => 'container' ] );
# my $request = PUT $uri;

# List Containers
# my $uri = URI->new("https://$account.blob.core.windows.net/");
# $uri->query_form( [ comp => 'list' ] );
# my $request = GET $uri;

# Get Container Properties
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer");
# $uri->query_form( [ restype => 'container' ] );
# my $request = GET $uri;

# Put Container Metadata
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer");
# $uri->query_form( [ restype => 'container', comp => 'metadata' ] );
# my $request = PUT $uri, ':x-ms-meta-Category' => 'Images';

# Get Container Metadata
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer");
# $uri->query_form( [ restype => 'container', comp => 'metadata' ] );
# my $request = GET $uri;

# Get Container ACL
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer");
# $uri->query_form( [ restype => 'container', comp => 'acl' ] );
# my $request = GET $uri;

# Delete Container
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer");
# $uri->query_form( [ restype => 'container' ] );
# my $request = DELETE $uri;

# List Blobs
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer");
# $uri->query_form( [ restype => 'container', comp => 'list', include => 'metadata' ] );
# my $request = GET $uri;

# Put Blob
# my $uri = URI->new(
#    "https://$account.blob.core.windows.net/mycontainer/myblockblob");
# my $content = '<p>Hello there!</p>';
# my $request = PUT $uri,
#     'Content-Type'        => 'text/html; charset=UTF-8',
#     ':x-ms-meta-Category' => 'Web pages',
#     ':x-ms-blob-type'     => 'BlockBlob',
#     'Content-MD5'         => md5_base64($content) . '==',
#     'If-None-Match'       => '*',
#     'Content'             => $content;

# Get Blob
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer/myblockblob");
# my $request = GET $uri, 'If-Match', '0x8CE8CF67ABC00F3';

# Get Blob Properties
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer/myblockblob");
# my $request = HEAD $uri, 'If-Match', '0x8CE8CF67ABC00F3';

# Get Blob Metadata
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer/myblockblob");
# $uri->query_form( [ comp => 'metadata' ] );
# my $request = GET $uri, 'If-Match', '0x8CE8CF67ABC00F3';

# Set Blob Metadata
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer/myblockblob");
# $uri->query_form( [ comp => 'metadata' ] );
# my $request = PUT $uri, ':x-ms-meta-Colour', 'Orange', 'If-Match', '0x8CE8CF67ABC00F3';

# Lease Blob
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer/myblockblob");
# $uri->query_form( [ comp => 'lease' ] );
# my $request = PUT $uri, ':x-ms-lease-action', 'acquire';

# Delete Blob
# my $uri = URI->new("https://$account.blob.core.windows.net/mycontainer/myblockblob");
# my $request = DELETE $uri, 'If-Match', '0x8CE8CF7243F2B5C';

# Put Block
# my $uri
#     = URI->new("https://$account.blob.core.windows.net/mycontainer/myblob");
# $uri->query_form(
#     [ comp => 'block', blockid => encode_base64( '00000001', '' ) ] );
# my $content = '<p>Hello ';
# my $request = PUT $uri,
#     'Content-MD5' => md5_base64($content) . '==',
#     'Content'     => $content;

# my $uri
#     = URI->new("https://$account.blob.core.windows.net/mycontainer/myblob");
# $uri->query_form(
#     [ comp => 'block', blockid => encode_base64( '00000002', '' ) ] );
# my $content = 'there!</p>';
# my $request = PUT $uri,
#     'Content-MD5' => md5_base64($content) . '==',
#     'Content'     => $content;

# Put Block List
# my $uri
#     = URI->new("https://$account.blob.core.windows.net/mycontainer/myblob");
# $uri->query_form( [ comp => 'blocklist' ] );
# my $first  = encode_base64( '00000001', '' );
# my $second = encode_base64( '00000002', '' );
# my $content = qq{<?xml version="1.0" encoding="utf-8"?>
#  <BlockList>
#    <Uncommitted>$first</Uncommitted>
#    <Uncommitted>$second</Uncommitted>
#  </BlockList>};
# my $request = PUT $uri,
#     ':x-ms-blob-content-type' => 'text/html; charset=UTF-8',
#     ':x-ms-blob-content-md5'  => md5_base64('<p>Hello there!</p>') . '==',
#     ':x-ms-meta-Category'     => 'Web pages',
#     'Content-MD5'             => md5_base64($content) . '==',
#     'If-None-Match'           => '*',
#     'Content'                 => $content;

# Get Block List
# my $uri
#     = URI->new("https://$account.blob.core.windows.net/mycontainer/myblob");
# $uri->query_form( [ comp => 'blocklist' ] );
# my $request = GET $uri;

my $response = $blobservice->make_http_request($request);

if ( $response->is_success ) {
    if ( $response->content_type eq 'application/xml' ) {
        my $xml = $response->decoded_content;
        say $xml;
        my $dom = XML::LibXML->load_xml( string => $xml );
        say $dom->toString(1);
    } else {
        say $response->as_string;
    }
} else {
    die $response->status_line;
}
