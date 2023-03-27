package OpenAI::API::Error;

use Moo;
use strictures 2;
use namespace::clean;

extends 'Throwable::Error';

has request => (
    is  => 'ro',
    isa => sub { ref $_[0] eq 'HTTP::Request' or die "expected HTTP::Request object" },
);

has response => (
    is  => 'ro',
    isa => sub { ref $_[0] eq 'HTTP::Response' or die "expected HTTP::Response object" },
);

1;

__END__

=head1 NAME

OpenAI::API::Error - throwable error objects

=head1 SYNOPSIS

    use OpenAI::API::Error;

    OpenAI::API::Error->throw(
        message  => 'Something went wrong',
        request  => $req,
        response => $res,
    );

    # elsewhere...

    try {
        my $response = $openai->$method(...);
    } catch ($e) {
        # Handle error
    }

=head1 DESCRIPTION

The C<OpenAI::API::Error> module provides an object-oriented exception
mechanism for errors encountered while interacting with the OpenAI
API. It extends the L<Throwable::Error> class to include the optional
L<HTTP::Request> and L<HTTP::Response> objects, allowing for better
error reporting and debugging.

=head1 ATTRIBUTES

=head2 request

The C<request> attribute holds the L<HTTP::Request> object associated
with the error.

=head2 response

The C<response> attribute holds the L<HTTP::Response> object associated
with the error.

=head1 METHODS

=head2 throw

The C<throw> method creates a new OpenAI::API::Error object with the
provided message, request, and response attributes and throws it as
an exception.

=head1 SEE ALSO

=over 4

=item *

L<Throwable::Error>

=item *

L<HTTP::Request>

=item *

L<HTTP::Response>

=back
