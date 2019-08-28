#!perl
use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'Mojolicious::Plugin::AWS::SNS';

my $t = Test::Mojo->new;

##
## canonical uri and query strings
##

## canonical uri
my $url = Mojo::URL->new('/documents and settings/');
is $t->app->canonical_uri($url), '/documents%2520and%2520settings/', 'canonical uri';
$url = Mojo::URL->new('/');
is $t->app->canonical_uri($url), '/', 'canonical empty uri';

## sorted parameters with multiple values
$url = Mojo::URL->new('/?b=21&b=3&a=1&c=3');
is $t->app->canonical_query_string($url), 'a=1&b=21&b=3&c=3', 'canonical query string';
$url = Mojo::URL->new('/?b=b&b=d&a=f&a=a');
is $t->app->canonical_query_string($url), 'a=a&a=f&b=b&b=d', 'canonical query string';

## URL encoded names and values
$url = Mojo::URL->new('/?joe+schmoe=good+boy');
is $t->app->canonical_query_string($url), 'joe%20schmoe=good%20boy', 'canonical query string';

## don't encode safe characters
$url = Mojo::URL->new('/?a=A-force&a=a-force&b=B_force&b=b_force&c=C.force&d=D~force');
is $t->app->canonical_query_string($url),
  'a=A-force&a=a-force&b=B_force&b=b_force&c=C.force&d=D~force', 'canonical query string';

##
## headers
##

## example from https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
my $headers = Mojo::Headers->new->parse(<<_HEADERS_);
Host:iam.amazonaws.com
Content-Type:application/x-www-form-urlencoded; charset=utf-8
My-header1:    a   b   c  
X-Amz-Date:20150830T123600Z
My-Header2:    "a   b   c"  

_HEADERS_

is $t->app->canonical_headers($headers->to_hash(1)), <<_HEADERS_, "canonical headers";
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
is $t->app->canonical_request(
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

is $t->app->canonical_request_hash($creq),
  'f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59', 'canonical request hash';

##
## string to sign (step 2)
##

## example from https://docs.aws.amazon.com/general/latest/gr/sigv4-create-string-to-sign.html
my $string_to_sign = qq{AWS4-HMAC-SHA256
20150830T123600Z
20150830/us-east-1/iam/aws4_request
f536975d06c0309214f805bb90ccff089219ecd68b2577efef23edd43b7e1a59};

is $t->app->string_to_sign(
    datetime => '2015-08-30T12:36:00Z',
    region   => 'us-east-1',
    service  => 'iam',
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
my $kSecret     = 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY';
my $signing_key = $t->app->signing_key(
    secret   => $kSecret,
    datetime => '2015-08-30T12:36:00Z',
    region   => 'us-east-1',
    service  => 'iam'
);
is hexify($signing_key), 'c4afb1cc5771d871763a393e44b703571b55cc28424d1a5e86da6ed3c154a4b9',
  'signing key';

is $t->app->signature(signing_key => $signing_key, string_to_sign => $string_to_sign),
  '5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7', 'calculate signature';

is $t->app->authorization_header(
    access_key       => 'AKIDEXAMPLE',
    credential_scope => '20150830/us-east-1/iam/aws4_request',
    signed_headers   => [qw/content-type host x-amz-date/],
    signature        => '5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7'
  )->to_string,
  'Authorization: AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/iam/aws4_request, SignedHeaders=content-type;host;x-amz-date, Signature=5d672d79c15b13162d9279b0855cfba6789a8edb4c82c400e06b5924a6f2b5d7',
  'authorization header';

##
## signed HTTP request
##
my $signed = $t->app->signed_request(
    datetime => Mojo::Date->new(1234567890),
    url      => Mojo::URL->new('https://sns.us-east-2.amazonaws.com'),
    form     => {
        Action           => 'Publish',
        TopicArn         => 'arn:aws:sns:us-east-2:123456789012:my-topic',
        Subject          => 'Test Subject',
        MessageStructure => 'json',
        Message => encode_json({default => 'Default message', https => 'An HTTP message'}),
        Version => '2010-03-31'
    },
    service    => 'sns',
    region     => 'us-east-2',
    access_key => 'ACCESSKEY',
    secret_key => 'SECRETKEY'
);

is $signed->req->headers->authorization . "\n", <<_HEADER_, 'authorization header';
AWS4-HMAC-SHA256 Credential=ACCESSKEY/20090213/us-east-2/sns/aws4_request, SignedHeaders=content-type;host;x-amz-date;accept, Signature=909e9fe2bfc00bdfced4984e3ae8f62452d916eda85a59c2d5bdd351bc1af91b
_HEADER_

is $signed->req->body . "\n", <<_BODY_, 'signed request body';
Action=Publish&Message=%7B%22default%22%3A%22Default+message%22%2C%22https%22%3A%22An+HTTP+message%22%7D&MessageStructure=json&Subject=Test+Subject&TopicArn=arn%3Aaws%3Asns%3Aus-east-2%3A123456789012%3Amy-topic&Version=2010-03-31
_BODY_

## The AWS user identified here with access/secret keys must have
## AmazonSNSFullAccess to write. I created a group with that permission, and
## then added a user to the group
if ($ENV{AWS_REGION} && $ENV{AWS_SNS_TOPIC_ARN} && $ENV{AWS_ACCESS_KEY} && $ENV{AWS_SECRET_KEY})
{
    my $aws_region = $ENV{AWS_REGION};
    my $access_key = $ENV{AWS_ACCESS_KEY};
    my $secret_key = $ENV{AWS_SECRET_KEY};
    my $topic      = $ENV{AWS_SNS_TOPIC_ARN};
    use Mojo::JSON 'encode_json';

    $t->app->sns_publish(
        region     => $aws_region,
        access_key => $access_key,
        secret_key => $secret_key,
        topic      => $topic,
        subject    => 'Automatic Message',
        message    => {
            default => 'default message',
            https   => encode_json({message => 'this is lamer than flour'})
        }
    )->then(
        sub {
            my $tx = shift;
            ok $tx->res->json('/PublishResponse/PublishResult/MessageId'),
              'response has message id'
              or diag explain $tx->res->json;
        }
    )->catch(
        sub {
            my $err = shift;
            ok !$err, "an error occurred"
              or diag "Error: $err";
        }
    )->wait;
}

done_testing();
