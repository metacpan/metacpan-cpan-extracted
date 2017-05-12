# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTTPHeaders.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

#die('update use test more line');
use Test::More tests => 40;
BEGIN { use_ok('Perlbal::XS::HTTPHeaders') };


my $fail = 0;
foreach my $constname (qw(
	H_REQUEST H_RESPONSE M_DELETE M_GET M_OPTIONS M_POST
	M_PUT M_HEAD)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined HTTPHeaders macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

################################################################################
## create some headers for future testing
my $reqstr = "GET / HTTP/1.1\r\nAccept: */*\r\nReferer: http://10.0.1.2/login.bml\r\nAccept-Language: en-us\r\nAccept-Encoding: gzip, deflate\r\nUser-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)\r\nHost: 10.0.1.2\r\nConnection: Keep-Alive\r\nCookie: ljsession=ws:test:8:1nB88NhuYz; BMLschemepref=dystopia\r\n\r\n";
my $resstr = "HTTP/1.0 200 OK\r\nContent-type: text/html\r\nContent-length: 15\r\nContent-language: en\r\nConnection: close\r\nDate: Mon, 25 Oct 2004 06:18:35 GMT\r\nETag: \"c756d7656d27e81f06e1ed31c2b47392\"\r\nServer: Apache/1.3.31 (Debian GNU/Linux) mod_perl/1.29\r\n\r\n";

################################################################################
## make sure we can create a headers object
my $hdr = Perlbal::XS::HTTPHeaders->new(\$reqstr);
isa_ok($hdr, 'Perlbal::XS::HTTPHeaders');

################################################################################
## verify that we parsed it right
is($hdr->getReconstructed(), $reqstr, 'request 1 reconstruction (1)');
is($hdr->getHeader('Referer'), "http://10.0.1.2/login.bml", 'header retrieval 1');
is($hdr->getHeader('Host'), "10.0.1.2", 'header retrieval 2');
is($hdr->getHeader('Not-Real'), undef, 'header retrieval 3');
is($hdr->getReconstructed(), $reqstr, 'request 1 reconstruction (2)');

################################################################################
## do some more header parsing etc
$hdr->setHeader('Host', 'random garbage');
is($hdr->getHeader('Host'), 'random garbage', 'header retrieval 4');
is($hdr->getHeader('host'), 'random garbage', 'header retrieval 5');
is($hdr->getHeader('HOST'), 'random garbage', 'header retrieval 6');
isnt($hdr->getReconstructed(), $reqstr, 'request 1 reconstruction (3)');
$hdr->setHeader('Host', '10.0.1.2');
is($hdr->getHeader('Host'), "10.0.1.2", 'header retrieval 8');
is($hdr->getReconstructed(), $reqstr, 'request 1 reconstruction (4)');


isnt($hdr->getURI(), "/foo.txt", "Haven't set the uri yet");
unlike($hdr->to_string(), qr{^GET /foo\.txt}, "First line doesn't contain foo.txt");
$hdr->setURI('/foo.txt');
is($hdr->getURI(), "/foo.txt", "We set the uri now");
like($hdr->to_string(), qr{^GET /foo\.txt}, "First line does contain foo.txt");

isnt($hdr->request_uri(), "/bar.txt", "Haven't set the uri yet");
unlike($hdr->to_string(), qr{^GET /bar\.txt}, "First line doesn't contain bar.txt");
$hdr->set_request_uri('/bar.txt');
is($hdr->request_uri(), "/bar.txt", "We set the uri now");
like($hdr->to_string(), qr{^GET /bar\.txt}, "First line does contain bar.txt");

my $headers_list = $hdr->headers_list;
is_deeply([sort @$headers_list], [qw/ Accept Accept-Encoding Accept-Language Connection Cookie Host Referer User-Agent /], 'headers_list');


################################################################################
## and yet some more
$hdr->setHeader('Host', undef);
is($hdr->getHeader('Host'), undef, 'header retrieval 7');
$hdr->setHeader('Host', '10.0.1.2');
is($hdr->getHeader('Host'), '10.0.1.2', 'header retrieval 8');

################################################################################
## let's test out reference stuff
$hdr = Perlbal::XS::HTTPHeaders->new(\$resstr);
isa_ok($hdr, 'Perlbal::XS::HTTPHeaders');
is($hdr->to_string, $resstr, 'response 1 reconstruction (1)');
my $ref = $hdr->to_string_ref;
is($$ref, $resstr, 'response 1 reconstruction (2)');

################################################################################
## new_response testing
$hdr = Perlbal::XS::HTTPHeaders->new_response(304);
isa_ok($hdr, 'Perlbal::XS::HTTPHeaders');
is($hdr->getStatusCode(), 304, 'new_response test 1');
is($hdr->getHeader('Test'), undef, 'new_response test 2');
$hdr->setHeader('Test', 'Testing');
is($hdr->getHeader('Test'), 'Testing', 'new_response test 3');
$hdr->setHeader('Test', undef);
is($hdr->getHeader('Test'), undef, 'new_response test 4');

################################################################################
## make sure we can't get the old style invalid headers
$hdr = Perlbal::XS::HTTPHeaders->new(\"HTTP/");
is($hdr, undef, 'old bad header test');

################################################################################
## check mapping from old to new
Perlbal::XS::HTTPHeaders::enable();
$hdr = Perlbal::HTTPHeaders->new(\$reqstr);
isa_ok($hdr, 'Perlbal::XS::HTTPHeaders');
$hdr = Perlbal::HTTPHeaders->new(\$resstr);
isa_ok($hdr, 'Perlbal::XS::HTTPHeaders');

################################################################################
## regression test to make sure this bug isn't reintroduced
$hdr = Perlbal::XS::HTTPHeaders->new(\"GET / HTTP/1.0\r\nHost: dog\r\n\r\n");
my $a = $hdr->getReconstructed();
$hdr->header('Host', undef);
$a = $hdr->getReconstructed();
$hdr->header('Cat', 'dog');
$a = $hdr->getReconstructed();
is(1, 1, 'regression test 1');

# test setting codetext
$hdr = Perlbal::XS::HTTPHeaders->new_response(404);
ok($hdr->getStatusCode() == 404, "code is 404");
$hdr->code(200, undef);
ok($hdr->getStatusCode() == 200, "code changed to 200");
like($hdr->to_string, qr/200 OK/, "firstLine set fine");

# vim: filetype=perl
