package RPC::Any::Interface::CGI;
use Moose::Role;
use HTTP::Request;
use HTTP::Status ();
use Scalar::Util qw(blessed);

# This must be composed AFTER the HTTP role.

around 'input_to_request' => sub {
    my $orig = shift;
    my $self = shift;
    my $input = shift;
    
    $self->exception('HTTPError', 'REQUEST_METHOD is not defined in the environment.')
        if !$ENV{'REQUEST_METHOD'};
        
    return $self->request_from_cgi($input);
};

sub request_from_cgi {
    my ($self, $input) = @_;
    my $request = HTTP::Request->new();
    $request->method($ENV{'REQUEST_METHOD'});
    $request->protocol($ENV{'SERVER_PROTOCOL'});
    $request->uri($ENV{'REQUEST_URI'});
    $request->content_type($ENV{'CONTENT_TYPE'});
    $request->content_length($ENV{'CONTENT_LENGTH'});
    # This is very simplistic. It doesn't convert multiple headers back into
    # multiple headers, because that's difficult to impossible. However, it
    # does everything we need.
    foreach my $key (keys %ENV) {
        next if $key !~ /^HTTP/;
        my $header_name = $key;
        $header_name =~ s/^HTTP_//;
        $request->header($header_name => $ENV{$key});
    }
    if (utf8::is_utf8($input)) {
        utf8::encode($input);
        $self->_set_request_utf8($request);
    }
    $request->content($input);
    return $request;
}

around 'produce_output' => sub {
    my $orig = shift;
    my $self = shift;
    my ($response) = @_;
    my $status = $response->code;
    my $message = $response->message || HTTP::Status::status_message($status);
    my $output = $self->$orig(@_);
    $output =~ s/^.+?\015\012/Status: $status $message\015\012/s;
    return $output;
};

1;

__END__

=head1 NAME

RPC::Any::Interface::CGI - HTTP support for RPC::Any::Server in CGI
environments

=head1 DESCRIPTION

In a CGI environment (like running under mod_cgi or mod_perl in Apache),
the HTTP headers aren't available on C<STDIN>--instead they are in
special environment variables. So RPC::Any CGI servers get their input
partly from the environment. So the "input" to C<handle_input> is
just the RPC data, and the HTTP headers are read from the environment.
(However, you can still pass a CGI server an L<HTTP::Request> object,
in which case it will ignore the environment.)

Also, in a CGI environment, you can't just print the
C<HTTP/1.1 200 OK> line at the top of the HTTP response, you have to send
a special header, like C<Status: 200 OK>. So CGI servers return their
output in that slightly different way.

All CGI servers are also L<HTTP|RPC::Any::HTTP> servers, so they have all
the capabilities specified in L<RPC::Any::HTTP>. They just take their
input and produce their output differently.