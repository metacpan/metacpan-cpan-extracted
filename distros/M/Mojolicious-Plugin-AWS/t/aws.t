#!perl
use Mojo::Base -strict;
use Test::More;
use Mojo::JSON 'encode_json';
use Mojo::URL;
use Mojo::Headers;
use Mojo::Date;
use Mojo::UserAgent;

use lib 'lib';
use_ok 'Mojo::AWS';
use_ok 'Mojo::AWS::S3';

my $aws = Mojo::AWS->new(
    service    => 'iam',
    region     => 'us-east-1',
    transactor => Mojo::UserAgent->new->transactor,
    access_key => 'ACCESSKEY',
    secret_key => 'SECRETKEY',
);

##
## canonical uri and query strings
##

## canonical uri
my $url = Mojo::URL->new('/documents and settings/');
is $aws->canonical_uri($url), '/documents%2520and%2520settings/', 'canonical uri';
$url = Mojo::URL->new('/');
is $aws->canonical_uri($url), '/', 'canonical empty uri';

## sorted parameters with multiple values
$url = Mojo::URL->new('/?b=21&b=3&a=1&c=3');
is $aws->canonical_query_string($url), 'a=1&b=21&b=3&c=3', 'canonical query string';
$url = Mojo::URL->new('/?b=b&b=d&a=f&a=a');
is $aws->canonical_query_string($url), 'a=a&a=f&b=b&b=d', 'canonical query string';

## URL encoded names and values
$url = Mojo::URL->new('/?joe+schmoe=good+boy');
is $aws->canonical_query_string($url), 'joe%20schmoe=good%20boy', 'canonical query string';

## don't encode safe characters
$url = Mojo::URL->new('/?a=A-force&a=a-force&b=B_force&b=b_force&c=C.force&d=D~force');
is $aws->canonical_query_string($url),
  'a=A-force&a=a-force&b=B_force&b=b_force&c=C.force&d=D~force', 'canonical query string';

## canonical_uri for s3 objects
$aws = Mojo::AWS::S3->new(
    service    => 'iam',
    region     => 'us-east-1',
    transactor => Mojo::UserAgent->new->transactor,
    access_key => 'ACCESSKEY',
    secret_key => 'SECRETKEY',
);

$url = Mojo::URL->new('/example bucket//myphoto.jpg'); ## Mojo::URL does most of our canonicalization for us
is $aws->canonical_uri($url), '/example%20bucket//myphoto.jpg', 'canonical s3 uri';

##
## headers
##

$aws = Mojo::AWS->new(
    service    => 'iam',
    region     => 'us-east-1',
    transactor => Mojo::UserAgent->new->transactor,
    access_key => 'ACCESSKEY',
    secret_key => 'SECRETKEY',
);

## example from https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
my $headers = Mojo::Headers->new->parse(<<_HEADERS_);
Host:iam.amazonaws.com
Content-Type:application/x-www-form-urlencoded; charset=utf-8
My-header1:    a   b   c  
X-Amz-Date:20150830T123600Z
My-Header2:    "a   b   c"  

_HEADERS_

is $aws->canonical_headers($headers->to_hash(1)), <<_HEADERS_, "canonical headers";
content-type:application/x-www-form-urlencoded; charset=utf-8
host:iam.amazonaws.com
my-header1:a b c
my-header2:"a b c"
x-amz-date:20150830T123600Z
_HEADERS_

## example from https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
my $creq = qq{GET
/
Action=ListUsers&Version=2010-05-08
content-type:application/x-www-form-urlencoded; charset=utf-8
host:iam.amazonaws.com
x-amz-date:20150830T123600Z

content-type;host;x-amz-date
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855};

$url = Mojo::URL->new('https://iam.amazonaws.com/?Version=2010-05-08&Action=ListUsers');
is $aws->canonical_request(
    url     => $url,
    method  => 'GET',
    headers => {
        'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8',
        Host           => 'iam.amazonaws.com',
        'x-amz-date'   => '20150830T123600Z'
    },
    signed_headers => [qw/content-type host x-amz-date/],
    payload        => ''
  ),
  $creq, 'canonical request';

is $aws->canonical_request_hash($creq),
  'f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59', 'canonical request hash';

##
## string to sign (step 2)
##

## example from https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
my $string_to_sign = qq{AWS4-HMAC-SHA256
20150830T123600Z
20150830/us-east-1/iam/aws4_request
f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59};

is $aws->string_to_sign(
    datetime => '2015-08-30T12:36:00Z',
    hash     => 'f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59'
  ),
  $string_to_sign, 'string to sign';

##
## calculate signature (step 3)
##

sub hexify {
    join '' => map { unpack "H*" => $_ } split // => shift;
}

## example from https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
use Digest::SHA;

$aws = Mojo::AWS->new(
    region     => 'us-east-1',
    service    => 'iam',
    transactor => Mojo::UserAgent->new->transactor,
    access_key => 'ACCESSKEY',
    secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
);

my $signing_key = $aws->signing_key(datetime => '2015-08-30T12:36:00Z',);
is hexify($signing_key), 'c4afb1cc5771d871763a393e44b703571b55cc28424d1a5e86da6ed3c154a4b9',
  'signing key';

is $aws->signature(signing_key => $signing_key, string_to_sign => $string_to_sign),
  '5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7', 'calculate signature';

$aws = Mojo::AWS->new(
    region     => 'us-east-1',
    service    => 'iam',
    transactor => Mojo::UserAgent->new->transactor,
    access_key => 'AKIDEXAMPLE',
    secret_key => '',
);

is $aws->authorization_header(
    credential_scope => '20150830/us-east-1/iam/aws4_request',
    signed_headers   => [qw/content-type host x-amz-date/],
    signature        => '5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7'
  )->to_string,
  'Authorization: AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/iam/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7',
  'authorization header';

##
## signed HTTP request
##
$aws = Mojo::AWS->new(
    region     => 'us-east-2',
    service    => 'sns',
    transactor => Mojo::UserAgent->new->transactor,
    access_key => 'ACCESSKEY',
    secret_key => 'SECRETKEY',
);

my $signed = $aws->signed_request(
    method         => 'POST',
    datetime       => Mojo::Date->new(1234567890),
    url            => Mojo::URL->new('https://sns.us-east-2.amazonaws.com'),
    signed_headers => {'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8'},
    payload        => [
        form => {
            Action           => 'Publish',
            TopicArn         => 'arn:aws:sns:us-east-2:123456789012:my-topic',
            Subject          => 'Test Subject',
            MessageStructure => 'json',
            Message => encode_json({default => 'Default message', https => 'An HTTP message'}),
            Version => '2010-03-31'
        }
    ]
);

is $signed->req->headers->authorization . "\n", <<_HEADER_, 'authorization header';
AWS4-HMAC-SHA256 Credential=ACCESSKEY/20090213/us-east-2/sns/aws4_request, SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date, Signature=446f404455f7b65058223501857ef61f7d86d27056279ea06680bbb804d71001
_HEADER_

is $signed->req->body . "\n", <<_BODY_, 'signed request body';
Action=Publish&Message=%7B%22default%22%3A%22Default+message%22%2C%22https%22%3A%22An+HTTP+message%22%7D&MessageStructure=json&Subject=Test+Subject&TopicArn=arn%3Aaws%3Asns%3Aus-east-2%3A123456789012%3Amy-topic&Version=2010-03-31
_BODY_

done_testing();
