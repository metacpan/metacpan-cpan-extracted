package RPC::Any::Server::XMLRPC::CGI;
use Moose;
extends 'RPC::Any::Server::XMLRPC::HTTP';
with "RPC::Any::Interface::CGI";

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

RPC::Any::Server::XMLRPC::CGI - An XML-RPC server for a CGI environment

=head1 SYNOPSIS

 use RPC::Any::Server::XMLRPC::CGI;
 # Create a server where calling Foo.bar will call My::Module->bar.
 my $server = RPC::Any::Server::XMLRPC::CGI->new(
    dispatch  => { 'Foo' => 'My::Module' },
    send_nil  => 0,
    allow_get => 0,
 );
 # Read from STDIN + the environment, and print result, including HTTP
 # headers for a CGI environment, to STDOUT.
 print $server->handle_input();

 # HTTP & CGI servers also take HTTP::Request objects, if you want.
 my $request = HTTP::Request->new(POST => '/');
 $request->content('<?xml ... ');
 print $server->handle_input($request);

=head1 DESCRIPTION

This is a subclass of L<RPC::Any::Server::XMLRPC::HTTP> that
has the functionality described in L<RPC::Any::Interface::CGI>.
Baically, it's just like the HTTP server, but it works properly
in a CGI environment (where HTTP headers are in environment
variables instead of on STDIN).