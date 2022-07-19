package Net::Amazon::S3::Operation::Objects::Delete::Request;
# ABSTRACT: An internal class to delete multiple objects from a bucket
$Net::Amazon::S3::Operation::Objects::Delete::Request::VERSION = '0.991';
use Moose 0.85;
use Carp qw/croak/;

extends 'Net::Amazon::S3::Request::Bucket';

has 'keys'      => ( is => 'ro', isa => 'ArrayRef',   required => 1 );

with 'Net::Amazon::S3::Request::Role::HTTP::Header::Content_md5';
with 'Net::Amazon::S3::Request::Role::HTTP::Method::POST';
with 'Net::Amazon::S3::Request::Role::Query::Action::Delete';
with 'Net::Amazon::S3::Request::Role::XML::Content';

__PACKAGE__->meta->make_immutable;

sub _request_content {
	my ($self) = @_;

	return $self->_build_xml (Delete => [
		{ Quiet => 'true' },
		map +{ Object => [ { Key => $_ } ] }, @{ $self->keys }
	]);
}

sub BUILD {
	my ($self) = @_;

	croak "The maximum number of keys is 1000"
		if (scalar(@{$self->keys}) > 1000);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Objects::Delete::Request - An internal class to delete multiple objects from a bucket

=head1 VERSION

version 0.991

=head1 SYNOPSIS

	my $http_request = Net::Amazon::S3::Operation::Objects::Delete::Request->new (
		s3      => $s3,
		bucket  => $bucket,
		keys    => [$key1, $key2],
	);

=head1 DESCRIPTION

This module deletes multiple objects from a bucket.

Implements operation L<< DeleteObjects|https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteObjects.html >>

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
