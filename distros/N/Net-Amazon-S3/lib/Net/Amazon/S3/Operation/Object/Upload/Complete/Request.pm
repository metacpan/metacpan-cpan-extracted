package Net::Amazon::S3::Operation::Object::Upload::Complete::Request;
# ABSTRACT: An internal class to complete a multipart upload
$Net::Amazon::S3::Operation::Object::Upload::Complete::Request::VERSION = '0.992';
use Moose 0.85;
use Carp qw/croak/;

extends 'Net::Amazon::S3::Request::Object';

with 'Net::Amazon::S3::Request::Role::HTTP::Method::POST';
with 'Net::Amazon::S3::Request::Role::Query::Param::Upload_id';
with 'Net::Amazon::S3::Request::Role::XML::Content';

has 'etags'         => ( is => 'ro', isa => 'ArrayRef',   required => 1 );
has 'part_numbers'  => ( is => 'ro', isa => 'ArrayRef',   required => 1 );

__PACKAGE__->meta->make_immutable;

sub _request_content {
	my ($self) = @_;

	return $self->_build_xml (CompleteMultipartUpload => [
		map +{ Part => [
			{ PartNumber => $self->part_numbers->[$_] },
			{ ETag       => $self->etags->[$_] },
		]}, 0 ..  (@{$self->part_numbers} - 1)
	]);
}

sub BUILD {
	my ($self) = @_;

	croak "must have an equally sized list of etags and part numbers"
		unless scalar(@{$self->part_numbers}) == scalar(@{$self->etags});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Upload::Complete::Request - An internal class to complete a multipart upload

=head1 VERSION

version 0.992

=head1 SYNOPSIS

	my $request = Net::Amazon::S3::Operation::Object::Upload::Complete::Request->new (
		s3           => $s3,
		bucket       => $bucket,
		etags        => \@etags,
		part_numbers => \@part_numbers,
	);

=head1 DESCRIPTION

This module completes a multipart upload.

Implements operation L<< CompleteMultipartUpload|https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html >>

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
