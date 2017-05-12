use lib "t/lib";
use File::Copy;
use Test::More tests=>78;

BEGIN{
    use_ok( "Net::HTTPServer" );
    use_ok( "Net::HTTPServer::Session" );
    use_ok( "Net::HTTPServer::Request" );
}

my $server = new Net::HTTPServer(sessions=>1,datadir=>"t/sessions",log=>"t/access.log");
ok( defined($server), "new()");
isa_ok( $server, "Net::HTTPServer");

my $request = new Net::HTTPServer::Request();
ok( defined($request), "new()");
isa_ok( $request, "Net::HTTPServer::Request");

is_deeply( $request->Cookie(), {}, "No cookies");
is_deeply( $request->Env(), {}, "No environment");
is_deeply( $request->Header(), {}, "No headers");
is( $request->Method(), undef, "No method");
is( $request->Path(), undef, "No path");
is( $request->Request(), undef, "No request");
is( $request->URL(), undef, "No URL");

#-----------------------------------------------------------------------------
# requests/req1
#-----------------------------------------------------------------------------
my $file1 = &readFile("t/requests/req1");
my $request1 =
    new Net::HTTPServer::Request(request=>$file1,
                                 server=>$server,
                                );
ok( defined($request1), "new()");
isa_ok( $request1, "Net::HTTPServer::Request");

is_deeply( $request1->Cookie(), {}, "No cookies");
is_deeply( $request1->Env(), {}, "No environment");
is_deeply( $request1->Header(),
{
    "host"=>"localhost:8001",
    "user-agent"=>"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7) Gecko/20040624 Debian/1.7-2",
    "accept"=>"text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
    "accept-encoding"=>"gzip,deflate",
    "accept-charset"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
    "keep-alive"=>"300",
    "connection"=>"keep-alive",
}, "Some headers");

is( $request1->Method(), "GET", "method == GET");
is( $request1->Path(), "/", "path == /");
is( $request1->Request(), $file1, "Requests match");
is( $request1->URL(), "/", "URL == /");

is( $request1->Header("test"), undef, "Header(test) = undef");
is( $request1->Header("Host"), "localhost:8001", "Header(Host) = localhost:8001");
is( $request1->Header("host"), "localhost:8001", "Header(host) = localhost:8001");
is( $request1->Header("HOST"), "localhost:8001", "Header(HOST) = localhost:8001");

#-----------------------------------------------------------------------------
# requests/req2
#-----------------------------------------------------------------------------
my $file2 = &readFile("t/requests/req2");
my $request2 =
    new Net::HTTPServer::Request(request=>$file2,
                                 server=>$server,
                                );
ok( defined($request2), "new()");
isa_ok( $request2, "Net::HTTPServer::Request");

is_deeply( $request2->Cookie(), {}, "No cookies");
is_deeply( $request2->Env(), {}, "No environment");
is_deeply( $request2->Header(),
{
    "host"=>"localhost:8001",
    "user-agent"=>"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7) Gecko/20040624 Debian/1.7-2",
    "accept"=>"image/png,*/*;q=0.5",
    "accept-encoding"=>"gzip,deflate",
    "accept-charset"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
    "keep-alive"=>"300",
    "connection"=>"keep-alive",
    "authorization"=>'Digest username="foo", realm="Test", nonce="MTA4ODcxNzc1Njo5YjNjMDA2NmYzZjVjMGU5OGEwOTg0YTk2YzBiZmFkMA==", uri="/perl-logo.jpg", algorithm=MD5, response="3f0d34d8e103b2a57b3f86a74cbea3cc", qop=auth, nc=00000001, cnonce="bd25b487957ed9a2"',
    "referer"=>"http://localhost:8001/",
}, "Some headers");

is( $request2->Method(), "GET", "method == GET");
is( $request2->Path(), "/perl-logo.jpg", "path == /perl-logo.jpg");
is( $request2->Request(), $file2, "Requests match");
is( $request2->URL(), "/perl-logo.jpg", "URL == /perl-logo.jpg");

#-----------------------------------------------------------------------------
# requests/req3
#-----------------------------------------------------------------------------
my $file3 = &readFile("t/requests/req3");
my $request3 =
    new Net::HTTPServer::Request(request=>$file3,
                                 server=>$server,
                                );
ok( defined($request3), "new()");
isa_ok( $request3, "Net::HTTPServer::Request");

is_deeply( $request3->Cookie(),
{
    "NETHTTPSERVERSESSION"=>"ea209023f1f3908dd9a39c256be04e55",
}, "One cookie");
is_deeply( $request3->Env(), {}, "No environment");
is_deeply( $request3->Header(),
{
    "host"=>"localhost:8001",
    "user-agent"=>"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7) Gecko/20040624 Debian/1.7-2",
    "accept"=>"text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
    "accept-encoding"=>"gzip,deflate",
    "accept-charset"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
    "keep-alive"=>"300",
    "connection"=>"keep-alive",
    "authorization"=>'Digest username="foo", realm="Test", nonce="MTA4ODcxNzg2Mzo5YmE3MWZjN2EzOGIzOWM5YWJhZjFiM2RkNjkyNTU4MQ==", uri="/session", algorithm=MD5, response="baa2e104080fb5964e0dfcc4cb2280ff", qop=auth, nc=00000002, cnonce="29d500603edc385b"',
    "cache-control"=>"max-age=0",
    "cookie"=>"NETHTTPSERVERSESSION=ea209023f1f3908dd9a39c256be04e55",
}, "Some headers");

is( $request3->Method(), "GET", "method == GET");
is( $request3->Path(), "/session", "path == /session");
is( $request3->Request(), $file3, "Requests match");
is( $request3->URL(), "/session", "URL == /session");

is( $request3->Cookie("test"),undef, "cookie(test) == undef");
is( $request3->Cookie("NETHTTPSERVERSESSION"),"ea209023f1f3908dd9a39c256be04e55", "cookie(NETHTTPSERVERSESSION) == ea209023f1f3908dd9a39c256be04e55");

File::Copy::cp("t/req_sessions/ea209023f1f3908dd9a39c256be04e55","t/sessions/ea209023f1f3908dd9a39c256be04e55");

my $session = $request3->Session();
ok( defined($session), "Session()");
isa_ok( $session, "Net::HTTPServer::Session");

ok( !$session->Exists("test"), "test does not exist");
ok( $session->Exists("foo"), "foo exists");
ok( $session->Exists("bar"), "bar exists");
is( $session->Get("foo"), "bar", "foo = bar");
is_deeply( $session->Get("bar"), ["1","2","b"], "bar = [1,2,b]" );

#-----------------------------------------------------------------------------
# requests/req4
#-----------------------------------------------------------------------------
my $file4 = &readFile("t/requests/req4");
my $request4 =
    new Net::HTTPServer::Request(request=>$file4,
                                 server=>$server,
                                );
ok( defined($request4), "new()");
isa_ok( $request4, "Net::HTTPServer::Request");

is_deeply( $request4->Cookie(),
{
    "NETHTTPSERVERSESSION"=>"ea209023f1f3908dd9a39c256be04e55",
}, "One cookie");
is_deeply( $request4->Env(),
{
    "file1"=>"/home/reatmon/devel/diff_test/test",
    "file2"=>"/home/reatmon/devel/diff_test/test2",
}, "Two vars");
is_deeply( $request4->Header(),
{
    "host"=>"localhost:8001",
    "user-agent"=>"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7) Gecko/20040624 Debian/1.7-2",
    "accept"=>"text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
    "accept-encoding"=>"gzip,deflate",
    "accept-charset"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
    "keep-alive"=>"300",
    "connection"=>"keep-alive",
    "authorization"=>'Digest username="foo", realm="Test", nonce="MTA4ODcxODkxMzo5YmE3MWZjN2EzOGIzOWM5YWJhZjFiM2RkNjkyNTU4MQ==", uri="/foo/bar.pl", algorithm=MD5, response="ecf1ef3fcc82d9cab6849fa986118311", qop=auth, nc=00000003, cnonce="2a1b2b1e0723ba9e"',
    "cookie"=>"NETHTTPSERVERSESSION=ea209023f1f3908dd9a39c256be04e55",
    "content-length"=>"102",
    "content-type"=>"application/x-www-form-urlencoded",
    "referer"=>"http://localhost:8001/test.html",
}, "Some headers");

is( $request4->Method(), "POST", "method == POST");
is( $request4->Path(), "/foo/bar.pl", "path == /foo/bar.pl");
is( $request4->Request(), $file4, "Requests match");
is( $request4->URL(), "/foo/bar.pl", "URL == /foo/bar.pl");

is( $request4->Env("test"),undef,"env(test) == undef");
is( $request4->Env("file1"),"/home/reatmon/devel/diff_test/test","env(file1) == /home/reatmon/devel/diff_test/test");
is( $request4->Env("file2"),"/home/reatmon/devel/diff_test/test2","env(file2) == /home/reatmon/devel/diff_test/test2");

#-----------------------------------------------------------------------------
# requests/req5
#-----------------------------------------------------------------------------
my $file5 = &readFile("t/requests/req5");
my $request5 =
    new Net::HTTPServer::Request(request=>$file5,
                                 server=>$server,
                                );
ok( defined($request5), "new()");
isa_ok( $request5, "Net::HTTPServer::Request");

is_deeply( $request5->Cookie(),
{
    "NETHTTPSERVERSESSION"=>"ea209023f1f3908dd9a39c256be04e55",
}, "One cookie");
is_deeply( $request5->Env(),
{
    "test1"=>"foo",
    "test2"=>"bar",
}, "Two vars");
is_deeply( $request5->Header(),
{
    "host"=>"localhost:8001",
    "user-agent"=>"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7) Gecko/20040624 Debian/1.7-2",
    "accept"=>"text/xml,application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5",
    "accept-encoding"=>"gzip,deflate",
    "accept-charset"=>"ISO-8859-1,utf-8;q=0.7,*;q=0.7",
    "keep-alive"=>"300",
    "connection"=>"keep-alive",
    "authorization"=>'Digest username="foo", realm="Test", nonce="MTA4ODcxODk1ODo5YmE3MWZjN2EzOGIzOWM5YWJhZjFiM2RkNjkyNTU4MQ==", uri="/env.pl?test1=foo&test2=bar", algorithm=MD5, response="ed962b59fa90def8432cf04916539a2a", qop=auth, nc=00000001, cnonce="1e0d10d8225dc588"',
    "cookie"=>"NETHTTPSERVERSESSION=ea209023f1f3908dd9a39c256be04e55",
}, "Some headers");

is( $request5->Method(), "GET", "method == GET");
is( $request5->Path(), "/env.pl", "path == /env.pl");
is( $request5->Request(), $file5, "Requests match");
is( $request5->URL(), "/env.pl?test1=foo&test2=bar", "URL == /env.pl?test1=foo&test2=bar");

is( $request5->Env("test"),undef,"env(test) == undef");
is( $request5->Env("test1"),"foo","env(test1) == foo");
is( $request5->Env("test2"),"bar","env(test2) == bar");




sub readFile
{
    my $file = shift;

    open(FILE,$file);
    my $data = join("",<FILE>);
    close(FILE);
    return $data;
}


