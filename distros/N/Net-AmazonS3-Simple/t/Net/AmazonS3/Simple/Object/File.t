use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;
use HTTP::Response;
use Digest::MD5 qw(md5_hex);
use Path::Tiny;

use_ok('Net::AmazonS3::Simple::Object::File');

my $content = "--SOME-CONTENT--";
our $etag = md5_hex("$content\n");
my $content_length = length $content;

my $object_file_path = Path::Tiny->tempfile();
$object_file_path->spew_raw("$content\n");

my $obj = Net::AmazonS3::Simple::Object::File->create_from_response(
    validate  => 1,
    response  => HTTP::Response->parse(msg()),
    file_path => $object_file_path,
);

is($obj->etag,             $etag,           'etag');
is($obj->content_length,   $content_length, 'content_length');
is($obj->content_encoding, undef,           'content_encoding');
is($obj->last_modified,    1466080120,      'last_modified');
is($obj->content,          "$content\n",    'content');

throws_ok {
    local $etag = 'xx';
    Net::AmazonS3::Simple::Object::File->create_from_response(
        validate => 1,
        response => HTTP::Response->parse(msg()),
        file_path => $object_file_path,
    );

}
qr/^Object content/, 'invalid object content';

sub msg {
    return <<EOF;
HTTP/1.1 200 OK
Connection: close
Date: Sat, 22 Oct 2016 20:10:07 GMT
Accept-Ranges: bytes
ETag: "$etag"
Server: AmazonS3
Content-Encoding:
Content-Length: $content_length
Content-Type: text/plain
Last-Modified: Thu, 16 Jun 2016 12:28:40 GMT
Client-Date: Sat, 22 Oct 2016 20:10:06 GMT
Client-Peer: 54.231.192.32:80
Client-Response-Num: 1
X-Amz-Id-2: /bp/eY0PDOuiOqOrW5yx9EvbJ6x/qBX5XPRUQr8kEfUhRu0BeS86T8UeoqaTMA6c4O5oeZOk32Y=
X-Amz-Request-Id: BC8936DD6346508C

$content
EOF
}
