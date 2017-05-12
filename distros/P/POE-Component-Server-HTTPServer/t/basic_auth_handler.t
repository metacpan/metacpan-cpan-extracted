use Test::More 'no_plan'; # tests => 10;

use HTTP::Status;
use HTTP::Response;
use HTTP::Request;
use MIME::Base64;

BEGIN { 
  use_ok('POE::Component::Server::HTTPServer');
  use_ok('POE::Component::Server::HTTPServer::Handler');
  use_ok('POE::Component::Server::HTTPServer::BasicAuthenHandler');
};

my $h = new_handler( 'BasicAuthenHandler', 'testRealm' );
ok( defined($h), 'constructor returns defined' );
isa_ok( $h, 'POE::Component::Server::HTTPServer::Handler' );
can_ok( $h, 'handle' );
isa_ok( $h, 'POE::Component::Server::HTTPServer::BasicAuthenHandler' );

{ # test the challenge response
  my $resp = HTTP::Response->new( RC_OK );
  my $req = HTTP::Request->new();
  # $req->header('Authorization', undef);
  my $retval = $h->handle( { response => $resp, request => $req } );
  ok( $retval == H_FINAL, 'Handler finalized response' );
  ok( $resp->code == RC_UNAUTHORIZED, 'Response has correct 403 code' );
  ok( $resp->header('WWW-Authenticate') eq 'Basic realm="testRealm"',
      "Response has proper header for auth" );
}

{ # test the authenticating response
  my $resp = HTTP::Response->new( RC_OK );
  my $req = HTTP::Request->new();
  my $cred_plain = "testUser:testPass";
  my $cred_md5 = encode_base64($cred_plain);
  $req->header('Authorization', "Basic $cred_md5");
  my $ctx = { response => $resp, request => $req };
  my $retval = $h->handle( $ctx );
  ok( $retval == H_CONT, 'Handler did not finalize response' );
  ok( $ctx->{basic_username} = 'testUser', "Handler decoded username" );
  ok( $ctx->{basic_password} = 'testPass', "Handler decoded password" );
}




