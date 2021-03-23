package Net::Amazon::S3::Operation::Object::Tags::Add::Request;
# ABSTRACT: Internal class to build PutObjectTagging request
$Net::Amazon::S3::Operation::Object::Tags::Add::Request::VERSION = '0.98';
use Moose 0.85;

extends 'Net::Amazon::S3::Request::Object';

with 'Net::Amazon::S3::Request::Role::Tags::Add';
with 'Net::Amazon::S3::Request::Role::Query::Param::Version_id';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Tags::Add::Request - Internal class to build PutObjectTagging request

=head1 VERSION

version 0.98

=head1 SYNOPSIS

	my $request = Net::Amazon::S3::Operation::Bucket::Tags::Add::Request->new (
		s3      => $s3,
		bucket  => $bucket,
		key     => $key,
		tags    => { tag1 => 'val1', ... },
	);

=head1 DESCRIPTION

This module implements request of L<PUT Object tagging|https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectPUTtagging.html>
operation.

=head1 PROPERIES

=head2 tags

Mandattory.

Hashref, key/value tag pairs

=head2 version_id

Optional.

When specified tags on given version will be set.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is a part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
