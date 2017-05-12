use Modern::Perl;
package Net::OpenXchange::X::HTTP;
BEGIN {
  $Net::OpenXchange::X::HTTP::VERSION = '0.001';
}

use Moose;

# ABSTRACT: Exception class for HTTP errors

extends 'Throwable::Error';

has request => (
    is       => 'ro',
    required => 1,
);

has response => (
    is       => 'ro',
    required => 1,
);

has 'message' => (
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
);

has 'status_line' => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_message {
    my ($self) = @_;
    return sprintf 'HTTP error %s during %s %s', $self->response->status_line,
      $self->request->method, $self->request->uri;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::X::HTTP - Exception class for HTTP errors

=head1 VERSION

version 0.001

=head1 SYNOPSIS

        Net::OpenXchange::X::HTTP->throw({
            request => $req,
            response => $res,
        });

Net::OpenXchange::X::HTTP is an exception class used for errors on the HTTP
level that occur before decoding OpenXchange's JSON response body.

=head1 ATTRIBUTES

=head2 request

Required, instance of L<HTTP::Request|HTTP::Request> which was sent.

=head2 response

Required, instance of L<HTTP::Response|HTTP::Response> which was received and
contained the error

=head2 message

Defaults to a string describing the error with HTTP status line, request URI
and request method.

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

