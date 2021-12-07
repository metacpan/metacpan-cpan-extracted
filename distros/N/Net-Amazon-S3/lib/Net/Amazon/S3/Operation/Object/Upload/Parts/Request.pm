package Net::Amazon::S3::Operation::Object::Upload::Parts::Request;
# ABSTRACT: List the parts in a multipart upload.
$Net::Amazon::S3::Operation::Object::Upload::Parts::Request::VERSION = '0.99';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request::Object';

with 'Net::Amazon::S3::Request::Role::Query::Param::Upload_id';
with 'Net::Amazon::S3::Request::Role::HTTP::Method::GET';

has 'headers' =>
	( is => 'ro', isa => 'HashRef', required => 0, default => sub { {} } );

__PACKAGE__->meta->make_immutable;

sub _request_headers {
	my ($self) = @_;

	return %{ $self->headers };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Upload::Parts::Request - List the parts in a multipart upload.

=head1 VERSION

version 0.99

=head1 DESCRIPTION

Implements an operation L<< ListParts|https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListParts.html >>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
