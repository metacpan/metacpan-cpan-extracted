package Net::Amazon::S3::Operation::Object::Fetch::Request;
# ABSTRACT: An internal class to get an object
$Net::Amazon::S3::Operation::Object::Fetch::Request::VERSION = '0.991';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;

extends 'Net::Amazon::S3::Request::Object';

with 'Net::Amazon::S3::Request::Role::HTTP::Method';

has 'range'
	=> is       => 'ro'
	=> isa      => 'Str'
	;

override _request_headers => sub {
	my ($self) = @_;

	return (
		super,
		(Range => $self->range) x defined $self->range,
	);
};

__PACKAGE__->meta->make_immutable;

sub query_string_authentication_uri {
	my ( $self, $expires, $query_form ) = @_;

	my $uri = URI->new( $self->_request_path );
	$uri->query_form( %$query_form ) if $query_form;

	return $self->_build_signed_request(
		path   => $uri->as_string,
	)->query_string_authentication_uri($expires);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Operation::Object::Fetch::Request - An internal class to get an object

=head1 VERSION

version 0.991

=head1 SYNOPSIS

	my $http_request = Net::Amazon::S3::Operation::Object::Fetch::Request->new (
		s3     => $s3,
		bucket => $bucket,
		key    => $key,
		method => 'GET',
	);

=head1 DESCRIPTION

Implements operation L<< GetObject|https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html >>.

This module gets an object.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method returns a HTTP::Request object.

=head2 query_string_authentication_uri

This method returns query string authentication URI.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
