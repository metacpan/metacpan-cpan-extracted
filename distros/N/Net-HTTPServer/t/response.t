use lib "t/lib";
use Test::More tests=>26;

BEGIN{ use_ok( "Net::HTTPServer::Response" ); }

my $response = new Net::HTTPServer::Response();
ok( defined($response), "new()");
isa_ok( $response, "Net::HTTPServer::Response");

my @build = $response->_build();
is_deeply( \@build, ["HTTP/1.1 200\r\n\r\n",""] , "_build: Blank" );

$response->Header("Test","test");
ok( $response->Header("Test"), "Header Test exists");
is( $response->Header("Test"), "test", "Header Test == test");

@build = $response->_build();
is_deeply( \@build, ["HTTP/1.1 200\nTest: test\r\n\r\n",""] , "_build: Header" );

$response->Cookie("Test","test");

@build = $response->_build();
is_deeply( \@build, ["HTTP/1.1 200\nTest: test\nSet-Cookie: Test=test\r\n\r\n",""] , "_build: Cookie" );

$response->Cookie("Test","test",expires=>"expires",domain=>"domain",path=>"path",secure=>1);

@build = $response->_build();
is_deeply( \@build, ["HTTP/1.1 200\nTest: test\nSet-Cookie: Test=test;domain=domain;expires=expires;path=path;secure\r\n\r\n",""] , "_build: Full cookie" );

is( $response->Code(), 200, "Code == 200");
$response->Code(400);
isnt( $response->Code(), 200, "Code != 200");
is( $response->Code(), 400, "Code == 400");

@build = $response->_build();
is_deeply( \@build, ["HTTP/1.1 400\nTest: test\nSet-Cookie: Test=test;domain=domain;expires=expires;path=path;secure\r\n\r\n",""] , "_build: New code" );

is( $response->Body(), "", "Body == " );
$response->Body("Test body");
is( $response->Body(), "Test body", "Body == Test body" );

@build = $response->_build();
is_deeply( \@build, ["HTTP/1.1 400\nTest: test\nSet-Cookie: Test=test;domain=domain;expires=expires;path=path;secure\r\n\r\n","Test body"] , "_build: Body" );

is( $response->Body(), "Test body", "Body == Test body" );
$response->Clear();
is( $response->Body(), "", "Body == " );

@build = $response->_build();
is_deeply( \@build, ["HTTP/1.1 400\nTest: test\nSet-Cookie: Test=test;domain=domain;expires=expires;path=path;secure\r\n\r\n",""] , "_build: Clear" );

is( $response->Body(), "", "Body == " );
$response->Print("Test");
is( $response->Body(), "Test", "Body == Test" );
$response->Print(" body");
is( $response->Body(), "Test body", "Body == Test body" );


@build = $response->_build();
is_deeply( \@build, ["HTTP/1.1 400\nTest: test\nSet-Cookie: Test=test;domain=domain;expires=expires;path=path;secure\r\n\r\n","Test body"] , "_build: Print" );

my $response2 = new Net::HTTPServer::Response();
ok( defined($response2), "new()");
isa_ok( $response2, "Net::HTTPServer::Response");

$response2->Redirect("http://www.server.com/path");
@build = $response2->_build();
is_deeply( \@build, ["HTTP/1.1 307\nLocation: http://www.server.com/path\r\n\r\n",""] , "_build: Redirect" );


