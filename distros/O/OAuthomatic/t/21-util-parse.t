#!perl

use strict;
use warnings;

use Test::Most tests => 10;
use Encode;
use utf8;

my $req;
my $outp;

use_ok('OAuthomatic::Internal::Util', qw(parse_http_msg_form));


$req = HTTP::Request->parse(<<'END');
POST /path/script.cgi HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 32

home=Cosby&favorite+flavor=flies
END

$outp = parse_http_msg_form($req);
cmp_deeply($outp, {
    home => 'Cosby', 'favorite flavor' => 'flies',
   }, "parse 1 - simple");


$req = HTTP::Request->parse(<<'END');
POST /path/script.cgi HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 11

a=1&b=2&c=3
END

$outp = parse_http_msg_form($req);
cmp_deeply($outp, {
    a => 1, b => 2, c => 3,
   }, "parse 2 - simple");


$req = HTTP::Request->parse(<<'END');
POST /path/script.cgi HTTP/1.0
Content-Type: application/x-www-form-urlencoded; charset=utf-8
Content-Length: 32

b+c=x%26y&a=%C5%BC%C3%B3%C5%82ty
END

$outp = parse_http_msg_form($req);
cmp_deeply($outp, {
    a => 'żółty', 'b c' => 'x&y',
   }, "parse 3 - utf8");


$req = HTTP::Request->parse(<<'END');
POST /path/script.cgi HTTP/1.0
Content-Type: application/x-www-form-urlencoded; charset=iso-8859-2
Content-Length: 23

b+c=x%26y&a=%AF%F3%B3ty
END

$outp = parse_http_msg_form($req);
cmp_deeply($outp, {
    a => 'Żółty', 'b c' => 'x&y',
   }, "parse 4 - iso");


$req = HTTP::Request->parse(<<'END');
POST /path/script.cgi HTTP/1.0
Content-Type: text/plain
Content-Length: 11

a=1&b=2&c=3
END

$outp = parse_http_msg_form($req, 1);
cmp_deeply($outp, {
    a => 1, b => 2, c => 3,
   }, "parse 5 - bad content type with force");


$req = HTTP::Request->parse(<<'END');
POST /path/script.cgi HTTP/1.0
Content-Type: text/plain
Content-Length: 11

a=1&b=2&c=3
END

$outp = parse_http_msg_form($req);
cmp_deeply($outp, {}, "parse 6 - bad content type");


$req = HTTP::Request->parse(<<'END');
POST /path/script.cgi HTTP/1.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 11

ala ma kota
END

$outp = parse_http_msg_form($req);
cmp_deeply($outp, {}, "parse 7 - bad content");


$req = HTTP::Response->parse(<<'END');
Date: Sat, 17 Jan 2015 23:47:12 GMT
Server: Apache-Coyote/1.1
Vary: Accept-Encoding
Content-Length: 240
Content-Type: text/plain
Client-Date: Sat, 17 Jan 2015 23:47:13 GMT
Client-Peer: 91.225.248.132:443
Client-Response-Num: 1
Client-SSL-Cert-Issuer: /C=US/O=DigiCert Inc/CN=DigiCert SHA2 Secure Server CA
Client-SSL-Cert-Subject: /C=US/ST=California/L=Mountain View/O=LinkedIn Corporation/CN=tablet.linkedin.com
Client-SSL-Cipher: ECDHE-RSA-AES128-SHA256
Client-SSL-Socket-Class: IO::Socket::SSL
Set-Cookie: lidc="b=TB11:g=30:u=1:i=1421538432:t=1421624832:s=954130774"; Expires=Sun, 18 Jan 2015 23:47:12 GMT; domain=.linkedin.com; Path=/
X-FS-UUID: 10512d49ac51ba1340acb660662b0000
X-Li-Fabric: prod-ltx1
X-Li-Pop: PROD-IDB2
X-LI-UUID: EFEtSaxRuhNArLZgZisAAA==

oauth_token=78--e4b64515-990e-4d4a-96ff-f9e88bc9213b&oauth_token_secret=xaa7234a-58ed-4bf1-aad4-aa783848c30b&oauth_callback_confirmed=true&xoauth_request_auth_url=https%3A%2F%2Fapi.linkedin.com%2Fuas%2Foauth%2Fauthorize&oauth_expires_in=599
END

# print STDERR "-" x 70, "\n", $req->dump(), "-" x 70, "\n";

$outp = parse_http_msg_form($req, 1);
cmp_deeply($outp, {
    oauth_token => '78--e4b64515-990e-4d4a-96ff-f9e88bc9213b',
    oauth_token_secret => 'xaa7234a-58ed-4bf1-aad4-aa783848c30b', 
    oauth_callback_confirmed => 'true',
    xoauth_request_auth_url => 'https://api.linkedin.com/uas/oauth/authorize',
    oauth_expires_in => 599,
   }, "parse 8 - realistic");

$outp = parse_http_msg_form($req);
cmp_deeply($outp, {}, "parse 9 - realistic with no force");

done_testing;
