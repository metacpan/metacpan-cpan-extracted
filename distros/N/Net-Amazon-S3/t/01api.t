#!perl
use warnings;
use strict;
use lib 'lib';
use Digest::MD5::File qw(file_md5_hex);
use Test::More;
use Test::Deep;
use FindBin;

my $DEFAULT_TEST_LOCATIONS = 'us-east-1,eu-west-1';

plan skip_all => 'Testing this module for real costs money. Enable it by setting true value to env variable AMAZON_S3_EXPENSIVE_TESTS'
    unless $ENV{'AMAZON_S3_EXPENSIVE_TESTS'};

plan skip_all => 'Required env variable AWS_ACCESS_KEY_ID not set.'
    unless $ENV{'AWS_ACCESS_KEY_ID'};

plan skip_all => 'Required env variable AWS_ACCESS_KEY_SECRET not set.'
    unless $ENV{'AWS_ACCESS_KEY_SECRET'};

diag "AMAZON_S3_TEST_LOCATIONS not set, using default $DEFAULT_TEST_LOCATIONS"
    unless $ENV{'AMAZON_S3_TEST_LOCATIONS'};

my @locations = split /,/, ($ENV{'AMAZON_S3_TEST_LOCATIONS'} || $DEFAULT_TEST_LOCATIONS);

plan tests => 37 * @locations + 1;

use_ok('Net::Amazon::S3');

use vars qw/$OWNER_ID $OWNER_DISPLAYNAME/;

my $aws_access_key_id     = $ENV{'AWS_ACCESS_KEY_ID'};
my $aws_secret_access_key = $ENV{'AWS_ACCESS_KEY_SECRET'};

my $s3 = Net::Amazon::S3->new(
    {   aws_access_key_id     => $aws_access_key_id,
        aws_secret_access_key => $aws_secret_access_key,
        retry                 => 1,
    }
);

# list all buckets that i own
my $response = $s3->buckets;

$OWNER_ID          = $response->{owner_id};
$OWNER_DISPLAYNAME = $response->{owner_displayname};

for my $location ( @locations ) {

    my $TEST_SUITE_LENGTH = 36; # without last delete ok
    my $bucket_obj;
    SKIP:
    {
        # create a bucket
        # make sure it's a valid hostname for EU testing
        my $bucketname = 'net-amazon-s3-test-' . lc($aws_access_key_id) . '-' . time;

        # for testing
        # my $bucket = $s3->bucket($bucketname); $bucket->delete_bucket; exit;

        $bucket_obj = $s3->add_bucket(
            {   bucket              => $bucketname,
                acl_short           => 'public-read',
                location_constraint => $location
            }
        ) or skip $s3->err . ": " . $s3->errstr, $TEST_SUITE_LENGTH;

        isa_ok $bucket_obj, "Net::Amazon::S3::Bucket";
        my $expected_location = $location;
        $expected_location = 'us-east-1' unless defined $expected_location;
        $expected_location = 'eu-west-1' if $expected_location eq 'EU';

        is( $bucket_obj->get_location_constraint, $expected_location, "bucket created in expected region" );

        like_acl_allusers_read($bucket_obj);
        ok( $bucket_obj->set_acl( { acl_short => 'private' } ), 'make bucket private using query parameters' );
        unlike_acl_allusers_read($bucket_obj);

        # another way to get a bucket object (does no network I/O,
        # assumes it already exists).  Read Net::Amazon::S3::Bucket.
        $bucket_obj = $s3->bucket($bucketname);
        isa_ok $bucket_obj, "Net::Amazon::S3::Bucket";

        # fetch contents of the bucket
        # note prefix, marker, max_keys options can be passed in
        $response = $bucket_obj->list
            or skip $s3->err . ": " . $s3->errstr, $TEST_SUITE_LENGTH - 6;

        cmp_deeply $response, superhashof({
            bucket       => $bucketname,
            prefix       => '',
            marker       => '',
            max_keys     => 1_000,
            is_truncated => 0,
            keys         => [],
        }, "list empty bucket");

        is( undef, $bucket_obj->get_key("non-existing-key"), "get non existing key" );

        my $keyname = 'testing.txt';

        {

            # Create a publicly readable key, then turn it private with a short acl.
            # This key will persist past the end of the block.
            my $value = 'T';
            $bucket_obj->add_key(
                $keyname, $value,
                {   content_type        => 'text/plain',
                    'x-amz-meta-colour' => 'orange',
                    acl_short           => 'public-read',
                }
            );

            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname",
                200, "can access the publicly readable key" );

            like_acl_allusers_read( $bucket_obj, $keyname );

            ok( $bucket_obj->set_acl(
                { key => $keyname, acl_short => 'private' }
            ), "change key policy of private using acl_short");

            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname",
                403, "cannot access the private key" );

            unlike_acl_allusers_read( $bucket_obj, $keyname );

            ok( $bucket_obj->set_acl(
                {   key     => $keyname,
                    acl_xml => acl_xml_from_acl_short('public-read')
                }
            ), "change key policy to public using acl_xml" );

            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname",
                200, "can access the publicly readable key after acl_xml set" );

            like_acl_allusers_read( $bucket_obj, $keyname );

            ok( $bucket_obj->set_acl(
                {   key     => $keyname,
                    acl_xml => acl_xml_from_acl_short('private')
                }
            ), "change key policy to private using acl_xml" );

            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname",
                403, "cannot access the private key after acl_xml set" );

            unlike_acl_allusers_read( $bucket_obj, $keyname );
        }

        {
            # Create a private key, then make it publicly readable with a short
            # acl.  Delete it at the end so we're back to having a single key in
            # the bucket.

            my $keyname2 = 'testing2.txt';
            my $value    = 'T2';
            $bucket_obj->add_key(
                $keyname2,
                $value,
                {   content_type        => 'text/plain',
                    'x-amz-meta-colour' => 'blue',
                    acl_short           => 'private',
                }
            );

            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname2",
                403, "cannot access the private key" );

            unlike_acl_allusers_read( $bucket_obj, $keyname2 );

            ok( $bucket_obj->set_acl(
                {
                    key => $keyname2, acl_short => 'public-read' }
            ),
                "change private key to public"
            );

            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname2",
                200, "can access the publicly readable key" );

            like_acl_allusers_read( $bucket_obj, $keyname2 );

            $bucket_obj->delete_key($keyname2);

        }

        {

            # Copy a key, keeping metadata
            my $keyname2 = 'testing2.txt';

            $bucket_obj->copy_key( $keyname2, "/$bucketname/$keyname" );

            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname2",
                403, "cannot access the private key" );

            # Overwrite, making publically readable
            $bucket_obj->copy_key( $keyname2, "/$bucketname/$keyname",
                                   {
                                       acl_short => 'public-read' } );

            sleep 1;
            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname2",
                200, "can access the publicly readable key" );

            # Now copy it over itself, making it private
            $bucket_obj->edit_metadata( $keyname2, { short_acl => 'private' } );

            is_request_response_code(
                "http://$bucketname.s3.amazonaws.com/$keyname2",
                403, "cannot access the private key" );

            # Get rid of it, bringing us back to only one key
            $bucket_obj->delete_key($keyname2);

            # Expect a nonexistent key copy to fail
            ok( !$bucket_obj->copy_key( "newkey", "/$bucketname/$keyname2" ),
                "Copying a nonexistent key fails" );
        }

        # list keys in the bucket
        $response = $bucket_obj->list
            or skip $s3->err . ": " . $s3->errstr, $TEST_SUITE_LENGTH - 28;

        cmp_deeply $response, superhashof({
            bucket =>       $bucketname,
            prefix =>       '',
            marker =>       '',
            max_keys =>     1_000,
            is_truncated => 0,
            keys => [ superhashof({
                key               => $keyname,
                # the etag is the MD5 of the value
                etag              => 'b9ece18c950afbfa6b0fdbfa4ff731d3',
                size              => 1,
                owner_id          => $OWNER_ID,
                owner_displayname => $OWNER_DISPLAYNAME,
            })],
        }), "list bucket with 1 key";

        # You can't delete a bucket with things in it
        ok( !$bucket_obj->delete_bucket(), "cannot delete non-empty bucket" );

        $bucket_obj->delete_key($keyname);

        # now play with the file methods
        my $README_FILE = "$FindBin::Bin/../README.md";
        my $README_DEST = "$FindBin::Bin/README.md";
        my $readme_md5  = file_md5_hex($README_FILE);
        my $readme_size = -s $README_FILE;
        $keyname .= "2";
        $bucket_obj->add_key_filename(
            $keyname, $README_FILE,
            {   content_type        => 'text/plain',
                'x-amz-meta-colour' => 'orangy',
            }
        );

        $response               =  $bucket_obj->get_key($keyname);
        cmp_deeply $response, superhashof({
            content_type        => 'text/plain',
            value               => re( qr/Amazon Digital Services/ ),
            etag                => $readme_md5,
            'x-amz-meta-colour' => 'orangy',
            content_length      => $readme_size,
        }), "fetch key-from-file into memory";

        unlink($README_DEST);
        $response = $bucket_obj->get_key_filename( $keyname, undef, $README_DEST );

        cmp_deeply $response, superhashof({
            content_type        => 'text/plain',
            value               => '',
            etag                => $readme_md5,
            'x-amz-meta-colour' => 'orangy',
            content_length      => $readme_size,
        }), "fetch key-from-file into file";

        is( file_md5_hex($README_DEST), $readme_md5, "downloaded key-from-file checksum match" );
        $bucket_obj->delete_key($keyname);

        # try empty files
        $keyname .= "3";
        $bucket_obj->add_key( $keyname, '' );
        $response = $bucket_obj->get_key($keyname);

        cmp_deeply $response, superhashof({
            value          => '',
            etag           => 'd41d8cd98f00b204e9800998ecf8427e',
            content_type   => 'binary/octet-stream',
            content_length => 0,
        }), "fetch empty key into memory";

        $bucket_obj->delete_key($keyname);

        # how about using add_key_filename?
        my $EMPTY_FILE = "$FindBin::Bin/empty";
        $keyname .= '4';
        open FILE, ">", $EMPTY_FILE
            or skip "Can't open $EMPTY_FILE for write: $!", $TEST_SUITE_LENGTH - 34;
        close FILE;
        $bucket_obj->add_key_filename( $keyname, $EMPTY_FILE );
        $response = $bucket_obj->get_key($keyname);
        cmp_deeply $response, superhashof({
            value          => '',
            etag           => 'd41d8cd98f00b204e9800998ecf8427e',
            content_type   => 'binary/octet-stream',
            content_length => 0,
        }), "fetch empty-key-from-file into memory";
        $bucket_obj->delete_key($keyname);
        unlink $EMPTY_FILE;

        # fetch contents of the bucket
        # note prefix, marker, max_keys options can be passed in
        $response = $bucket_obj->list
            or skip $s3->err . ": " . $s3->errstr, $TEST_SUITE_LENGTH - 35;
        cmp_deeply $response, superhashof({
            bucket       => $bucketname,
            prefix       => '',
            marker       => '',
            max_keys     => 1_000,
            is_truncated => 0,
            keys         => [],
        }), "list bucket with all keys deleted";
    }

    ok( $bucket_obj->delete_bucket() );
}

# see more docs in Net::Amazon::S3::Bucket

# local test methods
sub is_request_response_code {
    my ( $url, $code, $message ) = @_;
    my $request = HTTP::Request->new( 'GET', $url );

    #warn $request->as_string();
    my $response = $s3->ua->request($request);
    is( $response->code, $code, $message );
}

sub like_acl_allusers_read {
    my ( $bucketobj, $keyname ) = @_;
    my $message = acl_allusers_read_message( 'like', @_ );
    like( $bucketobj->get_acl($keyname), qr(AllUsers.+READ), $message );
}

sub unlike_acl_allusers_read {
    my ( $bucketobj, $keyname ) = @_;
    my $message = acl_allusers_read_message( 'unlike', @_ );
    unlike( $bucketobj->get_acl($keyname), qr(AllUsers.+READ), $message );
}

sub acl_allusers_read_message {
    my ( $like_or_unlike, $bucketobj, $keyname ) = @_;
    my $message
        = $like_or_unlike . "_acl_allusers_read: " . $bucketobj->bucket;
    $message .= " - $keyname" if $keyname;
    return $message;
}

sub acl_xml_from_acl_short {
    my $acl_short = shift || 'private';

    my $public_read = '';
    if ( $acl_short eq 'public-read' ) {
        $public_read = qq~
            <Grant>
                <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:type="Group">
                    <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
                </Grantee>
                <Permission>READ</Permission>
            </Grant>
        ~;
    }

    return qq~<?xml version="1.0" encoding="UTF-8"?>
    <AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
        <Owner>
            <ID>$OWNER_ID</ID>
            <DisplayName>$OWNER_DISPLAYNAME</DisplayName>
        </Owner>
        <AccessControlList>
            <Grant>
                <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:type="CanonicalUser">
                    <ID>$OWNER_ID</ID>
                    <DisplayName>$OWNER_DISPLAYNAME</DisplayName>
                </Grantee>
                <Permission>FULL_CONTROL</Permission>
            </Grant>
            $public_read
        </AccessControlList>
    </AccessControlPolicy>~;
}

