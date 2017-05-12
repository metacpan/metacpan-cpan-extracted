use strict;
use warnings;

use Test::More tests => 14;

BEGIN {
    chdir "t" if -e "t";
}

use Pod::Webserver;
ok 1;

# Test inlined time2str routine.
require Time::Local if $^O eq "MacOS";
my $offset = ($^O eq "MacOS") ? Time::Local::timegm(0,0,0,1,0,70) : 0;
my $time = (760233600 + $offset);  # assume broken POSIX counting of seconds
ok (Pod::Webserver::time2str($time), 'Thu, 03 Feb 1994 00:00:00 GMT');

# Test mock request object.
my $req = Pod::Webserver::Request->new(method=>'GET', url=>'http://www.cpan.org');
ok ($req);
ok ($req->method, 'GET');
ok ($req->url, 'http://www.cpan.org');

# Test mock response object.
$time = (1139520862 + $offset);
my $resp = Pod::Webserver::Response->new(200);
ok ($resp);
$resp->content('Dummy content.');
$resp->content_type( 'text/html' );
$resp->header( 'Last-Modified' => Pod::Webserver::time2str($time) );
$resp->header( 'Expires'       => Pod::Webserver::time2str($time) );

# Test mock connection object response.
my $testfile = 'dummysocket.txt';
open(my $fh, ">$testfile");
my $conn = Pod::Webserver::Connection->new(*$fh);
ok ($conn);
$conn->send_response($resp);
$conn->close;

my $captured_response;
{
    open(COMP, $testfile);
    local $/ = '';
    $captured_response = <COMP>;
    close COMP;
    unlink $testfile;
}
my $compare = "HTTP\/1.0 200 OK
Date: .* GMT
Content-Type: text\/html
Last-Modified: Thu, 09 Feb 2006 21:34:22 GMT
Expires: Thu, 09 Feb 2006 21:34:22 GMT

Dummy content.";
$compare =~ s/\n/\15\12/gs;
ok ($captured_response, qr/$compare/);

# Test mock connection object sending errors.
open($fh, ">$testfile");
$conn = Pod::Webserver::Connection->new(*$fh);
ok ($conn);
$conn->send_error('404');
$conn->close;

my $captured_error;
{
    open(COMP, $testfile);
    local $/ = '';
    $captured_error = <COMP>;
    close COMP;
    unlink $testfile;
}
$compare = "HTTP\/1.0 404 HTTP error code 404
Date: .* GMT
Content-Type: text\/plain

Something went wrong, generating code 404.";
$compare =~ s/\n/\15\12/gs;
ok ($captured_error, qr/$compare/);

# Test mock connection object retrieving requests.
open($fh, "+>$testfile");
print $fh "GET http://www.cpan.org/index.html HTTP/1.0\15\12";
close $fh;
open($fh, "$testfile");
$conn = Pod::Webserver::Connection->new(*$fh);
ok ($conn);
$req = $conn->get_request;
ok ($req);
if ($req) {
    ok ($req->method, 'GET');
    ok ($req->url, 'http://www.cpan.org/index.html');
} else {
    ok 0;
    ok 0;
}
$conn->close;
unlink $testfile;

exit;
