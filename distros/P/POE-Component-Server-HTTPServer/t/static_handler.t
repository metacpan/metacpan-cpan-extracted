# -*- perl -*-
use Test::More 'no_plan';

use HTTP::Status;
use HTTP::Response;

BEGIN { 
  use_ok('POE::Component::Server::HTTPServer');
  use_ok('POE::Component::Server::HTTPServer::Handler');
  use_ok('POE::Component::Server::HTTPServer::StaticHandler');
};

my $h = new_handler( 'StaticHandler', './t' );
ok( defined($h), 'constructor returns defined' );
isa_ok( $h, 'POE::Component::Server::HTTPServer::Handler' );
can_ok( $h, 'handle' );

# init: 'root' from $self
# input: 'contextpath' from context
# return: H_CONT if no such file/path
# - file -
# return: sets code(200), content-type, content on response; FINAL
#         on file read error, sets error_message on context; CONT
# - dir -
# init: index_file, auto_index from $self
# - index_file exists -
# return (read index_file)
# - auto_index true -
# return: set code(200), content-type, content on response; FINAL
#         set error_message on dir read error; CONT
# - else -
# return: CONT

=pod

 conditions:
 - file specified invalid (eg, "/fgoo")
 - file specified and exists and is read
 - file specified and exists and fail
 - file specified and not exists
 - dir specified and exists and is read
 - dir specified and exists and fail
 - dir specified and not exists

=cut


# this set of tests is dumb
{
  my $req = HTTP::Request->new();
  $req->uri( "http://www.example.com/bogus.doc" );
  $req->method("GET");
  my $resp = HTTP::Response->new( RC_NOT_FOUND ); # this shouldn't get reset
  my $retval = $h->handle( { request => $req, 
			     response => $resp,
			     contextpath => "/bogus.doc",
			   } );
  ok( $retval == H_CONT, "Handler couldn't finalize response (1)" );
  ok( $resp->code == RC_NOT_FOUND, 'Response has correct code' );
}

{
  my $req = HTTP::Request->new();
  $req->uri( "http://www.example.com/static_handler.t" );
  $req->method("GET");
  my $resp = HTTP::Response->new( RC_NOT_FOUND ); # this should get reset
  my $retval = $h->handle( { request => $req, 
			     response => $resp,
			     fullpath => $req->uri->path,
			     contextpath => "/static_handler.t",
			   } );
  ok( $retval == H_FINAL, 'Handler finalized response (2)' );
  ok( $resp->code == RC_OK, 'Response has correct code' );
  ok( $resp->content(), 'Response has content' );
}


