package Net::Amazon::S3::Signature;
# ABSTRACT: S3 Signature implementation base class
$Net::Amazon::S3::Signature::VERSION = '0.89';
use Moose;

has http_request => (
    is => 'ro',
    isa => 'Net::Amazon::S3::HTTPRequest',
);

sub sign_request {
    my ($self, $request);

    return;
}

sub sign_uri {
    my ($self, $uri, $expires_at);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Signature - S3 Signature implementation base class

=head1 VERSION

version 0.89

=head1 METHODS

=head2 new

Signature class should accept HTTPRequest instance and determine every
required parameter via this instance

=head2 sign_request( $request )

Signature class should return authenticated request based on given parameter.
Parameter can be modified.

=head2 sign_uri( $request, $expires_at? )

Signature class should return authenticated uri based on given request.

$expires_at is expiration time in seconds (epoch).
Default and maximal allowed value may depend on signature version.

Default request date is current time.
Signature class should accept provided C<< X-Amz-Date >> header instead (if signing request)
or query parameter (if signing uri)

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
