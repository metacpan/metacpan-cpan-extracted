#!/usr/bin/perl -w

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockModule;

local %ENV = ( HOME => '' );
require Net::Google::Drive::Simple;

my $mock_oauth = Test::MockModule->new('OAuth::Cmdline::GoogleDrive')->redefine( new => sub { bless { '__FAKE__' => 'mocked from ' . $0 }, 'OAuth::Cmdline::GoogleDrive' } )->redefine( authorization_headers => 1 );

my $json = JSON->new->allow_nonref;

my $data      = join "", <DATA>;
my $json_data = $json->decode($data) or die $data;

my $counter = 1;

my $mock_gd = Test::MockModule->new('Net::Google::Drive::Simple')->redefine( path_resolve => sub { ( 'root', 'root' ) } )->redefine( init => 1 )->redefine(
    http_json => sub {
        return $json_data if $counter++ == 1;
        return;
    }
);

my $mock_uri = Test::MockModule->new('URI::https')->redefine( query_form => 1 );

my $drive = Net::Google::Drive::Simple->new;

my $children = $drive->children("/");    # or any other folder /path/location

is scalar @$children, 2, "parsed two files";

my $first_file  = $children->[0];
my $second_file = $children->[1];

isa_ok $first_file,  'Net::Google::Drive::Simple::Item';
isa_ok $second_file, 'Net::Google::Drive::Simple::Item';

is $first_file->id, "0B6rF1m0B6rF1m0B6rF1m0B6rF1m0B6rF1m0B6rF1m", 'id';
is $first_file->Id, $first_file->id, 'Id eq id';
is $first_file->Id, $first_file->id, 'ID eq id';

is $first_file->labels => {
    'hidden'     => D(),
    'restricted' => D(),
    'starred'    => D(),
    'trashed'    => D(),
    'viewed'     => D()
  }
  or diag explain $first_file->labels;

ok $JSON::true;
is $first_file->copyable, $JSON::true, "copyable is true";

is $first_file->originalFilename, "sample.vcf",   "originalFilename";
is $first_file->mimeType,         "text/x-vcard", "mimeType";

ok !$first_file->is_folder, "not a folder";
ok $first_file->is_file, "first file is a file";

is $second_file->title, "second file title", "title for the second_file";

done_testing;

__DATA__
{
   "incompleteSearch" : false,
   "kind" : "drive#fileList",
   "DISABLED--nextPageToken" : "~!!~TOKEN-FOR-NEXT-PAGE",
   "etag" : "\"Q_eTag-to-be-filled\"",
   "items" : [
      {
         "labels" : {
            "viewed" : false,
            "restricted" : false,
            "hidden" : false,
            "starred" : false,
            "trashed" : false
         },
         "id" : "0B6rF1m0B6rF1m0B6rF1m0B6rF1m0B6rF1m0B6rF1m",
         "ownerNames" : [
            "One Username"
         ],
         "webContentLink" : "https://drive.google.com/XXXX",
         "lastModifyingUserName" : "One Username",
         "modifiedDate" : "2019-11-23T23:46:43.405Z",
         "mimeType" : "text/x-vcard",
         "createdDate" : "2019-11-23T07:14:21.000Z",
         "alternateLink" : "https://drive.google.com/XXXX",
         "md5Checksum" : "582a7e3a3caaec413d68a6888aacf5de",
         "etag" : "\"Q_i2RfdQZXXYrzCS85Kek3pR3ww/MTU3NDU1MjgwMzQwNQ\"",
         "fileSize" : "5477",
         "owners" : [
            {
               "permissionId" : "12595973245514046331",
               "displayName" : "One Username",
               "kind" : "drive#user",
               "isAuthenticatedUser" : true,
               "picture" : {
                  "url" : "https://lh3.googleusercontent.com/one-content"
               },
               "emailAddress" : "some+one@gmail.cow"
            }
         ],
         "copyable" : true,
         "headRevisionId" : "0B6rF1mVkRgjCSFR0UkoxVWV6RlNwSW5jbUtQSUtWcENBUms4PQ",
         "shared" : false,
         "markedViewedByMeDate" : "1970-01-01T00:00:00.000Z",
         "kind" : "drive#file",
         "copyRequiresWriterPermission" : false,
         "quotaBytesUsed" : "5477",
         "userPermission" : {
            "etag" : "\"Q_i2RfdQZXXYrzCS85Kek3pR3ww/NDR3wwA6Z8PvXSVX9s5vonPGWt4\"",
            "role" : "owner",
            "selfLink" : "https://www.googleapis.com/--do-something--",
            "type" : "user",
            "kind" : "drive#permission",
            "id" : "me"
         },
         "appDataContents" : false,
         "iconLink" : "https://drive-thirdparty.googleusercontent.com/16/type/text/x-vcard",
         "version" : "2",
         "explicitlyTrashed" : false,
         "selfLink" : "https://www.googleapis.com/--do-something--",
         "capabilities" : {
            "canEdit" : true,
            "canCopy" : true
         },
         "spaces" : [
            "drive"
         ],
         "modifiedByMeDate" : "2019-11-23T23:46:43.405Z",
         "editable" : true,
         "title" : "sample.vcf",
         "embedLink" : "https://drive.google.com/XXXX",
         "fileExtension" : "vcf",
         "writersCanShare" : true,
         "downloadUrl" : "https://doc-0g-1k-docs.googleusercontent.com/docs/securesc/mi1fsmu2njdpep8ch7uemunvn8pruh4k/76q4v93e7n15gd3nhn8qlt0rv1drstam/1577224800000/12595973245514046331/12595973245514046331/0B6rF1mVkRgjCT2RXNWlKNGNJTHNwNndRenZWSkpiX1Y5MWYw?e=download&gd=true",
         "lastModifyingUser" : {
            "isAuthenticatedUser" : true,
            "picture" : {
               "url" : "https://lh3.googleusercontent.com/one-content"
            },
            "emailAddress" : "some+one@gmail.cow",
            "kind" : "drive#user",
            "permissionId" : "12595973245514046331",
            "displayName" : "One Username"
         },
         "originalFilename" : "sample.vcf",
         "parents" : [
            {
               "parentLink" : "https://www.googleapis.com/--do-something--",
               "kind" : "drive#parentReference",
               "id" : "0AKjCUk9PVAjCUk9PVAjCUk9PVAg",
               "isRoot" : true,
               "selfLink" : "https://www.googleapis.com/--do-something--"
            }
         ]
      },
      {
         "spaces" : [
            "drive"
         ],
         "selfLink" : "https://www.googleapis.com/--do-something--",
         "capabilities" : {
            "canEdit" : true,
            "canCopy" : true
         },
         "modifiedByMeDate" : "2019-10-28T15:06:29.199Z",
         "editable" : true,
         "exportLinks" : {
            "application/zip" : "https://docs.google.com//--doc-doc-doc--",
            "application/vnd.oasis.opendocument.text" : "https://docs.google.com//--doc-doc-doc--",
            "application/epub+zip" : "https://docs.google.com//--doc-doc-doc--",
            "text/html" : "https://docs.google.com//--doc-doc-doc--",
            "application/pdf" : "https://docs.google.com//--doc-doc-doc--",
            "application/rtf" : "https://docs.google.com//--doc-doc-doc--",
            "text/plain" : "https://docs.google.com//--doc-doc-doc--",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" : "https://docs.google.com//--doc-doc-doc--"
         },
         "embedLink" : "https://docs.google.com//--doc-doc-doc--",
         "title" : "second file title",
         "lastModifyingUser" : {
            "permissionId" : "14292513505818522550",
            "kind" : "drive#user",
            "displayName" : "XYZ",
            "picture" : {
               "url" : "https://lh3.googleusercontent.com/one-content"
            },
            "emailAddress" : "someone@gmail.com",
            "isAuthenticatedUser" : false
         },
         "parents" : [
            {
               "id" : "0AKrF1mVkR1mVkR1mVkR",
               "kind" : "drive#parentReference",
               "parentLink" : "https://www.googleapis.com/--do-something--",
               "selfLink" : "https://www.googleapis.com/--do-something--",
               "isRoot" : true
            },
            {
               "selfLink" : "https://www.googleapis.com/--do-something--",
               "isRoot" : false,
               "id" : "0B2BS17zJM517zJM517zJM5",
               "parentLink" : "https://www.googleapis.com/--do-something--",
               "kind" : "drive#parentReference"
            }
         ],
         "writersCanShare" : true,
         "copyRequiresWriterPermission" : false,
         "quotaBytesUsed" : "0",
         "userPermission" : {
            "id" : "me",
            "kind" : "drive#permission",
            "selfLink" : "https://www.googleapis.com/--do-something--",
            "type" : "user",
            "role" : "owner",
            "etag" : "\"Q_i2RfdQZXXYrzCS85Kek3pR3ww/s32ORfrsqoiGnY6WHuQGippj0zs\""
         },
         "appDataContents" : false,
         "iconLink" : "https://drive-thirdparty.googleusercontent.com/16/type/application/vnd.google-apps.document",
         "version" : "143",
         "explicitlyTrashed" : false,
         "etag" : "\"Q_i2RfdQZXXYrzCS85Kek3pR3ww/MTU3NDA2MTAxOTAyMg\"",
         "owners" : [
            {
               "isAuthenticatedUser" : true,
               "emailAddress" : "some+one@gmail.cow",
               "picture" : {
                  "url" : "https://lh3.googleusercontent.com/one-content"
               },
               "permissionId" : "12595973245514046331",
               "displayName" : "One Username",
               "kind" : "drive#user"
            }
         ],
         "lastViewedByMeDate" : "2019-10-28T15:06:29.199Z",
         "copyable" : true,
         "shared" : true,
         "markedViewedByMeDate" : "1970-01-01T00:00:00.000Z",
         "kind" : "drive#file",
         "labels" : {
            "starred" : false,
            "trashed" : false,
            "hidden" : false,
            "viewed" : true,
            "restricted" : false
         },
         "modifiedDate" : "2019-11-18T07:10:19.022Z",
         "id" : "UTsIbpGb8HtlspGb8HtlspGb8HtlspGb8HtDRmZT",
         "lastModifyingUserName" : "Another User",
         "ownerNames" : [
            "One Username"
         ],
         "thumbnailLink" : "https://docs.google.com//--doc-doc-doc--",
         "mimeType" : "application/vnd.google-apps.document",
         "createdDate" : "2019-10-25T21:13:58.283Z",
         "alternateLink" : "https://docs.google.com//--doc-doc-doc--"
      }
   ],
   "selfLink" : "https://www.googleapis.com/--do-something--",
   "nextLink" : "https://www.googleapis.com/--do-something--"
}
