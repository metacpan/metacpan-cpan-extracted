#!/usr/bin/perl

use Carp;
use Net::SMTP::Server;
use Net::SMTP::Server::Client;
use Net::SMTP::Server::Relay;

$server = new Net::SMTP::Server('localhost', 25) ||
    croak("Unable to handle client connection: $!\n");

while($conn = $server->accept()) {
    # We can perform all sorts of checks here for spammers, ACLs,
    # and other useful stuff to check on a connection.
    
    # Handle the client's connection and spawn off a new parser.
    # This can/should be a fork() or a new thread,
    # but for simplicity...
    my $client = new Net::SMTP::Server::Client($conn) ||
	croak("Unable to handle client connection: $!\n");
    
    # Process the client.  This command will block until
    # the connecting client completes the SMTP transaction.
    $client->process || next;
    
    # In this simple server, we're just relaying everything
    # to a server.  If a real server were implemented, you
    # could save email to a file, or perform various other
    # actions on it here.
    my $relay = new Net::SMTP::Server::Relay($client->{FROM},
					     $client->{TO},
					     $client->{MSG});
}
