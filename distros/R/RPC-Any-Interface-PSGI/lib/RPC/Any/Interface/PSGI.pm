package RPC::Any::Interface::PSGI;

use strict;
use warnings;
use 5.008001;
our $VERSION = '0.03';

use Moose::Role;
use HTTP::Request;
use Plack::Request;

has _plack_req => (is => 'rw', isa => 'Plack::Request');

around 'get_input' => sub {
    my $orig = shift;
    my $self = shift;
    my $env = shift;

    $self->_plack_req(Plack::Request->new($env));
    return $self->_plack_req->content;
};

around 'input_to_request' => sub {
    my $orig = shift;
    my $self = shift;
    my $input = shift;

    my $request = HTTP::Request->new($self->_plack_req->method, $self->_plack_req->request_uri, $self->_plack_req->headers);
    $request->protocol($self->_plack_req->protocol);
    $request->content_type($self->_plack_req->content_type);
    $request->content_length($self->_plack_req->content_length);

    if (utf8::is_utf8($input)) {
        utf8::encode($input);
        $self->_set_request_utf8($request);
    }
    $request->content($input);

    return $request;
};

# HTTP role doesn't allow me to get headers and content seperately
# so I copied the header processing
around 'produce_output' => sub {
    my $orig = shift;
    my $self = shift;
    my $response = shift;

    my %headers = %{ $self->_output_headers };
    $response->header(%headers) if %headers;

    my @headers;
    $response->headers->scan(sub { push @headers, @_ });

    return [ $response->code, [ @headers ],  [ $response->content ] ];
};

1;

__END__

=head1 NAME

RPC::Any::Interface::PSGI - PSGI interface for RPC::Any

=head1 SYNOPSIS

  # in app.psgi
  use RPC::Any::Server::JSONRPC::PSGI;

  # Create a server where calling Foo.bar will call My::Module->bar.
  my $server = RPC::Any::Server::JSONRPC::PSGI->new(
      dispatch  => { 'Foo' => 'My::Module' },
      allow_get => 0,
  );

  my $handler = sub{ $server->handle_input(@_) };

=head1 DESCRIPTION

RPC::Any::Interface::PSGI is a PSGI interface for RPC::Any. It is based 
on RPC::Any::Interface::CGI and allows you to run RPC::Any::Server 
subclasses on any web servers that support PSGI.

This module cannot be used directly. You must use RPC::Any::Server
subclasses that consume this module such as 
RPC::Any::Server::JSONRPC::PSGI and RPC::Any::Server::XMLRPC::PSGI.

=head1 AUTHOR

Sherwin Daganato E<lt>sherwin@daganato.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<RPC::Any> L<Plack> L<PSGI>

=cut
