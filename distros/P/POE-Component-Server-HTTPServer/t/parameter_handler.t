# -*- perl -*- 
# Test ParameterParseHandler
#
use Test::More 'no_plan';

use HTTP::Status;
use HTTP::Response;
use HTTP::Request;

BEGIN {
  use_ok('POE::Component::Server::HTTPServer');
  use_ok('POE::Component::Server::HTTPServer::Handler');
  use_ok('POE::Component::Server::HTTPServer::ParameterParseHandler');
}

my $h = new_handler( 'ParameterParseHandler' );
ok( defined($h), "Constructor returns something" );
isa_ok( $h, 'POE::Component::Server::HTTPServer::Handler' );
can_ok( $h, 'handle' );
isa_ok( $h, 'POE::Component::Server::HTTPServer::ParameterParseHandler' );

{ # basic handle
  my $resp = HTTP::Response->new(RC_OK);
  my $req = HTTP::Request->new();
  $req->uri( "http://www.example.com/foo" );
  $req->method('GET');
  my $ctx = { request => $req, response => $resp };

  my $retval = $h->handle( $ctx );
  ok( $retval==H_CONT, "Handler did not finalize (1)" );
  ok( $resp->code == RC_OK, "Resp code unchanged (1)" );
}

{ # grab some GET params
  my $resp = HTTP::Response->new(RC_OK);
  my $req = HTTP::Request->new();
  $req->method('GET');
  $req->uri( "http://www.example.com/foo?true=false&black=white" );
  my $ctx = { request => $req, response => $resp };

  my $retval = $h->handle( $ctx );
  ok( $retval == H_CONT, "Handler did not finalize (2)" );
  ok( $resp->code == RC_OK, "Resp code unchanged (2)" );
  ok( $ctx->{param}->{true} = 'false', "Param set (2.a)" );
  ok( $ctx->{param}->{black} = 'white', "Param set (2.b)" );
}

{ # grab some POST params
  my $resp = HTTP::Response->new(RC_OK);
  my $req = HTTP::Request->new();
  $req->uri( "http://www.example.com" );
  $req->method('POST');
  $req->content_type( "application/x-www-form-urlencoded" );
  $req->content( "true=false&black=white" );
  my $ctx = { request => $req, response => $resp };

  my $retval = $h->handle( $ctx );
  ok( $retval == H_CONT, "Handler did not finalize (3)" );
  ok( $resp->code == RC_OK, "Resp code unchanged (3)" );
  ok( $ctx->{param}->{true} = 'false', "Param set (3.a)" );
  ok( $ctx->{param}->{black} = 'white', "Param set (3.b)" );
}

{ # grab some POST params, mixed with some GET params
  my $resp = HTTP::Response->new(RC_OK);
  my $req = HTTP::Request->new();
  $req->uri( "http://www.example.com/?black=white" );
  $req->method('POST');
  $req->content_type( "application/x-www-form-urlencoded" );
  $req->content( "true=false" );
  my $ctx = { request => $req, response => $resp };

  my $retval = $h->handle( $ctx );
  ok( $retval == H_CONT, "Handler did not finalize (4)" );
  ok( $resp->code == RC_OK, "Resp code unchanged (4)" );
  ok( $ctx->{param}->{true} = 'false', "Param set (4.a)" );
  ok( $ctx->{param}->{black} = 'white', "Param set (4.b)" );
}

#; { # POST with bad content-type (/encoding)
#;   # whoops, can't test, it just doesn't do anything
#; }


