package Net::Amazon::S3::Operation::Bucket::Create::Request;
# ABSTRACT: An internal class to create a bucket
$Net::Amazon::S3::Operation::Bucket::Create::Request::VERSION = '0.991';
use Moose 0.85;
extends 'Net::Amazon::S3::Request::Bucket';

with 'Net::Amazon::S3::Request::Role::HTTP::Header::ACL';
with 'Net::Amazon::S3::Request::Role::HTTP::Method::PUT';
with 'Net::Amazon::S3::Request::Role::XML::Content';

has location_constraint => (
	is => 'ro',
	isa => 'MaybeLocationConstraint',
	coerce => 1,
	required => 0,
);

__PACKAGE__->meta->make_immutable;

sub _request_content {
	my ($self) = @_;

	my $content = '';
	if (defined $self->location_constraint && $self->location_constraint ne 'us-east-1') {
		$content = $self->_build_xml (
			CreateBucketConfiguration => [
				{ LocationConstraint => $self->location_constraint },
			]
		);
	}

	return $content;
}

sub http_request {
	my $self = shift;

	return $self->_build_http_request (
		region  => 'us-east-1',
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Create::Request - An internal class to create a bucket

=head1 VERSION

version 0.991

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::Operation::Bucket::Create::Request->new(
    s3                  => $s3,
    bucket              => $bucket,
    acl_short           => $acl_short,
    location_constraint => $location_constraint,
  )->http_request;

=head1 DESCRIPTION

This module creates a bucket.

Implements operation L<< CreateBucket|https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html >>

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
