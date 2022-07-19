package Net::Amazon::S3::Operation::Bucket::Tags::Delete::Request;
# ABSTRACT: Internal class to build PutObjectTagging requests
$Net::Amazon::S3::Operation::Bucket::Tags::Delete::Request::VERSION = '0.991';
use Moose 0.85;

extends 'Net::Amazon::S3::Request::Bucket';

with 'Net::Amazon::S3::Request::Role::HTTP::Method::DELETE';
with 'Net::Amazon::S3::Request::Role::Query::Action::Tagging';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Bucket::Tags::Delete::Request - Internal class to build PutObjectTagging requests

=head1 VERSION

version 0.991

=head1 SYNOPSIS

	my $request = Net::Amazon::S3::Operation::Bucket::Tags::Delete::Request->new (
		s3      => $s3,
		bucket  => $bucket,
	);

=head1 DESCRIPTION

Implements a request part of an operation L<DeleteBucketTagging|https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucketTagging.html>

=head1 PROPERIES

=head2 tags

Key/value tag pairs

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is a part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
