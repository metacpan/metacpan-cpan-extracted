# -*- perl -*-
use warnings;
use strict;
use Test::More 'no_plan';
BEGIN {
  use_ok('POE::Component::Server::HTTPServer');
  use_ok('POE::Component::Server::HTTPServer::Handler');
}
use HTTP::Response;
use HTTP::Request;
use HTTP::Status;

my $s = 
  POE::Component::Server::HTTPServer->new( port => 9999,
					   log_file => undef,
					   #_debug => sub {
					     #print "> ",@_;
					   #},
					 );

sub new_context {
  my $uri = shift;
  my $req = HTTP::Request->new();
  $req->uri($uri);
  return { request => $req,
	   fullpath => $req->uri()->path(),
	   response => HTTP::Response->new( RC_OK ),
	   dispatcher => $s,
	   _dispatch_count => 0,
	 };

} # new_context()

sub dump_context {
  my $ctx = shift;
  foreach my $k (keys %$ctx) {
    print "c{$k}=$ctx->{$k}\n";
  }
}

{ # backstop handler test
  $s->handlers([]);
  my $ctx;
  $ctx = new_context( 'http://www.example.com/' );
  $s->dispatch( $ctx );
  ok( $ctx->{response}->code() eq RC_NOT_FOUND, "Basic backstop 404 (1)" );
  $ctx = new_context( 'http://www.example.com/foobar?blech=poop' );
  $s->dispatch( $ctx );
  ok( $ctx->{response}->code() eq RC_NOT_FOUND, "Basic backstop 404 (2)" );
}

{ # prefix tests
  $s->handlers([ '/foo' => sub { $_[0]->{foo}++; return H_CONT; },
		 '/bar' => sub { $_[0]->{bar}++; return H_CONT; },
		 '/foo/bar' => sub { $_[0]->{foobar}++; return H_CONT; },
	       ]);
  my $ctx;
  $ctx = new_context( "http://www.example.com/foo/thingie.html" );
  $s->dispatch( $ctx );
  ok( $ctx->{response}->code() eq RC_NOT_FOUND, "Fall through (foo)" );
  ok( $ctx->{foo} && !$ctx->{foobar} && !$ctx->{bar}, "Foo handled" );

  $ctx = new_context( "http://www.example.com/bar" );
  $s->dispatch( $ctx );
  ok( $ctx->{response}->code() eq RC_NOT_FOUND, "Fall through (bar)" );
  ok( $ctx->{bar} && !$ctx->{foo} && !$ctx->{foobar}, "Bar handled" );

  $ctx = new_context( "http://www.example.com/foo/bar/thingie.html" );
  $s->dispatch( $ctx );
  ok( $ctx->{response}->code() eq RC_NOT_FOUND, "Fall through (foobar)" );
  ok( $ctx->{foobar} && $ctx->{foo} && !$ctx->{bar}, "Foo/bar handled" );
}

