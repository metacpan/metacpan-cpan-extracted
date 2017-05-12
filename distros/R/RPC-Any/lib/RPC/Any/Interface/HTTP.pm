package RPC::Any::Interface::HTTP;
use Moose::Role;
use HTTP::Request;
use Scalar::Util qw(blessed);

has allow_get        => (is => 'rw', isa => 'Bool', default => 0);
has extra_headers    => (is => 'rw', isa => 'HashRef', default => sub { {} });
has last_request     => (is => 'rw', isa => 'HTTP::Request',
                         clearer => 'clear_last_request');
has _output_headers  => (is => 'ro', isa => 'HashRef', lazy_build => 1);
has _default_headers => (is => 'ro', isa => 'HashRef');

before 'get_input' => sub {
    my $self = shift;
    $self->clear_last_request();
};

# We have this here instead of on get_input because we want check_input
# to check the exact input, not $request->content. That is, we don't want
# to accidentally untaint the input by parsing it using input_to_request.
around 'decode_input_to_object' => sub {
    my $orig = shift;
    my $self = shift;
    my $input = shift;
    
    unless (blessed $input and $input->isa('HTTP::Request')) {
        $input = $self->input_to_request($input);
    }
    $self->exception('HTTPError', 'HTTP GET not allowed.')
        if (uc($input->method) eq 'GET' and !$self->allow_get);
    $self->last_request($input);
    
    unshift(@_, $input);
    return $self->$orig(@_);
};

sub input_to_request {
    my ($self, $input) = @_;
    my $is_utf8 = utf8::is_utf8($input);
    utf8::encode($input) if $is_utf8;
    my $request = HTTP::Request->parse($input);
    $self->_set_request_utf8($request) if $is_utf8;
    return $request;
}

sub http_content {
    my ($self, $request) = @_;
    if (uc($request->method) eq 'GET') {
        return $request->uri->query;
    }
    return $request->content;
}

sub _set_request_utf8 {
    my ($self, $request) = @_;
    # Assure that our decoders will properly re-decode a request's
    # as UTF-8 later.
    if (!$request->content_type_charset) {
        my $content_type = $request->content_type || 'text/plain';
        $request->content_type("$content_type; charset=UTF-8");
    }
}

around 'check_input' => sub {
    my $orig = shift;
    my $self = shift;
    if (blessed $_[0] and $_[0]->isa('HTTP::Request')) {
        my $input = shift;
        my $content = $self->http_content($input);
        unshift(@_, $content);
    }
    return $self->$orig(@_);
};

around 'produce_output' => sub {
    my $orig = shift;
    my $self = shift;
    my $response = shift;
    my %headers = %{ $self->_output_headers };
    $response->header(%headers) if %headers;
    my $output = $response->as_string("\015\012");
    unshift(@_, $output);
    return $self->$orig(@_);
};

sub _build__output_headers {
    my $self = shift;
    my %headers = %{ $self->_default_headers || {} };
    foreach my $key (keys %{ $self->extra_headers }) {
        $headers{$key} = $self->extra_headers->{$key};
    }
    return \%headers;
}

1;

__END__

=head1 NAME

RPC::Any::Interface::HTTP - HTTP input/output support for RPC::Any::Server

=head1 DESCRIPTION

This module houses code that is common to all the "HTTP" servers
in RPC::Any (L<RPC::Any::Server::XMLRPC::HTTP>
and L<RPC::Any::Server::JSONRPC::HTTP>). RPC::Any HTTP servers understand HTTP
input and return HTTP output. This means that HTTP servers expect
there to be HTTP headers on the input provided to C<handle_input>,
and they return HTTP headers as part of the return value of C<handle_input>.

So, if an HTTP server is reading from C<STDIN>, it expects both
the HTTP headers and the RPC input to be there.

HTTP servers also accept an L<HTTP::Request> object as input to
C<handle_input>.

=head1 HTTP SERVER ATTRIBUTES

Servers that use this code (including all the "HTTP" and "CGI" servers)
have certain additional attributes beyond the ones described in
L<RPC::Any::Server>. These can all be specified during C<new>
or set like C<< $server->method($value) >>. They are all optional.

=over

=item C<allow_get>

By default, RPC::Any's HTTP servers do not allow C<GET> requests,
because they have serious security issues that you as an implementor
have to take into account:

=over

=item *

You must never allow methods called with GET to modify data in your
application. Otherwise, a malicious website could cause a user
to modify data in your application when they did not intend to.
(This is a L<Cross-Site Request Forgery|http://en.wikipedia.org/wiki/Cross-site_request_forgery>.)

=item *

If your application uses cookies or HTTP authentication, you should be
careful about deciding whether or not to authenticate the user using
these methods during GET requests, if your application contains sensitive
data. During a GET request that was automatically authenticated with cookies,
It may be possible for a malicious web site to steal private
data from your application using authorized user accounts wihout
the user's permission.

=back

If you have addressed these security concerns in your application
and want to allow GET requests, you can set this to C<1> to allow them.

=item C<extra_headers>

This is a hashref that specifies extra HTTP headers that the server should
send back. The hash keys are the names of the headers, and the values
are the values for the headers. Any header specified here will override
the default headers sent by RPC::Any.

=item C<last_request>

An L<HTTP::Request> representing the last request that the server
processed. (Note for subclassers: this is not available until
C<decode_input_to_object>.)

=back