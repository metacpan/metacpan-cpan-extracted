#!/usr/bin/perl -w

use strict;
use warnings;
use POE qw( Component::Rendezvous::Publish Component::Server::HTTP );
use HTTP::Status;


my $port = $ENV{HTTP_PORT} || 8787;

my $http = POE::Component::Server::HTTP->new(
  Port => $port,
  ContentHandler => {
      '/' => \&respond,
  },
  Headers => {
    Server => 'My Rendezvous-aware HTTP server',
  },
);


my $publish = POE::Component::Rendezvous::Publish->create(
  name => 'simple http server',
  type => '_http._tcp',
  port => $port,
);


$poe_kernel->run;


sub respond {
  my ($request, $response) = @_;

  $response->code(RC_OK);
  $response->content("Yelllow, you fetched " . $request->uri);
  
  return RC_OK;
}

