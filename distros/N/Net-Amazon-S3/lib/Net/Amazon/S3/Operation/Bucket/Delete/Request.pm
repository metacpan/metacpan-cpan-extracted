package Net::Amazon::S3::Operation::Bucket::Delete::Request;
# ABSTRACT: An internal class to delete a bucket
$Net::Amazon::S3::Operation::Bucket::Delete::Request::VERSION = '0.98';
use Moose 0.85;
extends 'Net::Amazon::S3::Request::Bucket';

with 'Net::Amazon::S3::Request::Role::HTTP::Method::DELETE';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Delete::Request - An internal class to delete a bucket

=head1 VERSION

version 0.98

=head1 SYNOPSIS

	my $request = Net::Amazon::S3::Operation::Bucket::Delete::Request->new (
		s3     => $s3,
		bucket => $bucket,
	);

=head1 DESCRIPTION

This module deletes a bucket.

Implements operation L<< DeleteBucket|https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html >>

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
