use Modern::Perl;
package Net::OpenXchange::X::OX;
BEGIN {
  $Net::OpenXchange::X::OX::VERSION = '0.001';
}

use Moose;

# ABSTRACT: Exception class for OpenXchange errors

extends 'Throwable::Error';

has error => (
    is       => 'ro',
    required => 1,
    isa      => 'Str',
);

has error_params => (
    is       => 'ro',
    required => 1,
    isa      => 'ArrayRef',
);

has 'message' => (
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
);

sub _build_message {
    my ($self) = @_;
    return sprintf $self->error, @{ $self->error_params };
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;


__END__
=pod

=head1 NAME

Net::OpenXchange::X::OX - Exception class for OpenXchange errors

=head1 VERSION

version 0.001

=head1 SYNOPSIS

        Net::OpenXchange::X::OX->throw({
            error => $resdataref->{error},
            error_params => $resdataref->{error_params},
        });

Net::OpenXchange::X::OX is an exception class which is thrown when the JSON
response body from OpenXchange indicates an error.

=head1 ATTRIBUTES

=head2 error

Required, the error field of the response

=head2 error_params

Required, the error_params field of the response

=head2 message

Will be constructed automatically by interpolating the values of error_params
into error using sprintf

=head1 SEE ALSO

L<http://oxpedia.org/wiki/index.php?title=HTTP_API#Error_handling|http://oxpedia.org/wiki/index.php?title=HTTP_API#Error_handling>

=head1 AUTHOR

Maximilian Gass <maximilian.gass@credativ.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Maximilian Gass.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

