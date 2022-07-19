package Net::Amazon::S3::Operation::Buckets::List::Request;
$Net::Amazon::S3::Operation::Buckets::List::Request::VERSION = '0.991';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
extends 'Net::Amazon::S3::Request::Service';

# ABSTRACT: An internal class to list all buckets

with 'Net::Amazon::S3::Request::Role::HTTP::Method::GET';

__PACKAGE__->meta->make_immutable;

# AWS routes request without specific region to us-east-1
#
# https://docs.aws.amazon.com/general/latest/gr/rande.html

sub http_request {
	my $self    = shift;
	return $self->_build_http_request (
		use_virtual_host => 0,
		region => $self->s3->vendor->default_region,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Buckets::List::Request - An internal class to list all buckets

=head1 VERSION

version 0.991

=head1 SYNOPSIS

	my $request = Net::Amazon::S3::Operation::Buckets::List::Request->new (
		s3 => $s3,
	);

=head1 DESCRIPTION

This module lists all buckets.

Implements operation L<< ListBuckets|https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListBuckets.html >>

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
