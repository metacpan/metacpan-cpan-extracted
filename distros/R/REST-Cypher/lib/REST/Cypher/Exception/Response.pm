package REST::Cypher::Exception::Response;
{
  $REST::Cypher::Exception::Response::DIST = 'REST-Cypher';
}
# ABSTRACT handle REST API response exceptions
$REST::Cypher::Exception::Response::VERSION = '0.0.4';
use Moo;
extends 'REST::Cypher::Exception';

has response => ( is => 'ro', required => 1 );

has error    => ( is => 'ro', required => 1, lazy => 1, builder => '_build_error' );

sub message {
    # TODO return something more helpful (to our end user)
    return $_[0]->error->{message};
}


sub BUILD {
    my $self = shift;

    # force ->error to be built
    warn "failed a lazy build"
        unless $self->error;
}

sub _build_error {
    my $self = shift;
    $self->{error} = {
        code        => $self->response->code,
        message     => $self->response->message,
        as_string   => $self->response->as_string,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

REST::Cypher::Exception::Response

=head1 VERSION

version 0.0.4

=head1 CLASS ATTRIBUTES

=head2 response

Used to store the failed response.

=head2 error

Used to store the formatted data structure of error information from the
failed response.

=head1 METHODS

=head2 message

The value to return if we get strigified.

=head1 PRIVATE METHODS

=head2 BUILD

Make really certain that we have instantiated the C<error> attribute.

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
