package RPC::Any::Server::JSONRPC::HTTP;
use Moose;
use JSON::RPC::Common::Marshal::HTTP;
use HTTP::Response; # Needed because Marshal::HTTP doesn't load it.
extends 'RPC::Any::Server::JSONRPC';
with 'RPC::Any::Interface::HTTP';

has '+parser' => (isa => 'JSON::RPC::Common::Marshal::HTTP');

sub decode_input_to_object {
    my ($self, $request) = @_;
    if (uc($request->method) eq 'POST' and $request->content eq '') {
        $self->exception("ParseError",
                         "You did not supply any JSON to parse in the POST body.");
    }
    elsif (uc($request->method) eq 'GET' and !$request->uri->query) {
        $self->exception("ParseError",
                         "You did not supply any JSON to parse in the query string.");
    }
    my $call = eval { $self->parser->request_to_call($request) };
    if ($@) {
        $self->exception('ParseError',
                         "Error while parsing JSON HTTP request: $@");
    }
    return $call;
}

sub _build_parser {
    return JSON::RPC::Common::Marshal::HTTP->new();
}

sub encode_output_from_object {
    my ($self, $output_object) = @_;
    my $response = $self->parser->result_to_response($output_object);
    return $response;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

RPC::Any::Server::JSONRPC::HTTP - A JSON-RPC server that understands HTTP

=head1 SYNOPSIS

 use RPC::Any::Server::JSONRPC::HTTP;
 # Create a server where calling Foo.bar will call My::Module->bar.
 my $server = RPC::Any::Server::JSONRPC::HTTP->new(
    dispatch  => { 'Foo' => 'My::Module' },
    allow_get => 0,
 );
 # Read HTTP headers and JSON from STDIN and print result,
 # including HTTP headers, to STDOUT.
 print $server->handle_input();

 # HTTP servers also take HTTP::Request objects, if you want.
 my $request = HTTP::Request->new(POST => '/');
 $request->content('<?xml ... ');
 print $server->handle_input($request);

=head1 DESCRIPTION

This is a type of L<RPC::Any::Server::JSONRPC> that understands HTTP.
It has all of the features of L<RPC::Any::Server>, L<RPC::Any::Server::JSONRPC>,
and L<RPC::Any::Interface::HTTP>. You should see those modules for
information on configuring this server and the way it works.

The C<parser> attribute (which you usually don't need to care about) in
a JSONRPC::HTTP server is a L<JSON::RPC::Common::Marshal::HTTP> (as opposed
to the basic JSONRPC server, where it's a Marshal::Text instead of
Marshal::HTTP).

=head1 HTTP GET SUPPORT

Since this is based on L<JSON::RPC::Common>, it supports all the various
HTTP GET specifications in the various "JSON-RPC over HTTP" specs,
if you turn on C<allow_get>.