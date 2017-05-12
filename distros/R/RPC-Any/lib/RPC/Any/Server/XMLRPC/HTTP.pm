package RPC::Any::Server::XMLRPC::HTTP;
use Moose;
use HTTP::Status qw(RC_OK);
use HTTP::Response;
use URI::Escape qw(uri_unescape);
extends 'RPC::Any::Server::XMLRPC';
with 'RPC::Any::Interface::HTTP';

has '+_default_headers' => (default => \&DEFAULT_HEADERS);

use constant DEFAULT_HEADERS => {
    Accept => 'text/xml',
    Content_Type => 'text/xml; charset=UTF-8',
};

around 'http_content' => sub {
    my $orig = shift;
    my $self = shift;
    my ($request) = @_;
    my $content = $self->$orig(@_);
    if (uc($request->method) eq 'GET') {
        $content = uri_unescape($content);
    }
    return $content;
};

sub decode_input_to_object {
    my ($self, $request) = @_;
    my $content = $self->http_content($request);
    # If we don't pass RPC::XML a UTF-8 tagged string, it doesn't parse
    # UTF-8 properly.
    my $content_charset = $request->content_charset || '';
    if ($content_charset =~ /utf-8/i and !utf8::is_utf8($content)) {
        utf8::decode($content);
    }
    return $self->SUPER::decode_input_to_object($content);
}

sub encode_output_from_object {
    my $self = shift;
    my $output_string = $self->SUPER::encode_output_from_object(@_);
    my $response = HTTP::Response->new();
    utf8::encode($output_string) if utf8::is_utf8($output_string);
    $response->header(Content_Length => length $output_string);
    $response->code(RC_OK);
    $response->content($output_string);
    $response->protocol($self->last_request ? $self->last_request->protocol
                                            : 'HTTP/1.0');
    return $response;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

RPC::Any::Server::XMLRPC::HTTP - An XML-RPC server that understands HTTP

=head1 SYNOPSIS

 use RPC::Any::Server::XMLRPC::HTTP;
 # Create a server where calling Foo.bar will call My::Module->bar.
 my $server = RPC::Any::Server::XMLRPC::HTTP->new(
    dispatch  => { 'Foo' => 'My::Module' },
    send_nil  => 0,
    allow_get => 0,
 );
 # Read from STDIN and print result, including HTTP headers, to STDOUT.
 print $server->handle_input();

 # HTTP servers also take HTTP::Request objects, if you want.
 my $request = HTTP::Request->new(POST => '/');
 $request->content('<?xml ... ');
 print $server->handle_input($request);

=head1 DESCRIPTION

This is a type of L<RPC::Any::Server::XMLRPC> that understands HTTP.
It has all of the features of L<RPC::Any::Server>, L<RPC::Any::Server::XMLRPC>,
and L<RPC::Any::Interface::HTTP>. You should see those modules for
information on configuring this server and the way it works.

For the most part, this implementation ignores HTTP headers on input.
However, it can be helpful to specify C<charset=UTF-8> in your
Content-Type request header if you want Unicode to be handled properly.

=head1 HTTP GET SUPPORT

There is no support for HTTP GET in the normal XML-RPC spec. However,
if you have C<allow_get> set to 1, then this server will accept
a query string that is raw (URI-escaped) XML as its XML-RPC input,
during GET requests. So, for example, you could call GET on a URL like:

 /?%3C%3Fxml%20version%3D%221.0%22%3E%3CmethodCall%3E...

(That query string is the url-escaped version of
C<< <?xml version="1.0"><methodCall>... >>.)
