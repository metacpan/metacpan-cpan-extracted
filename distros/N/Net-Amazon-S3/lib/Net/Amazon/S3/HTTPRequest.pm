package Net::Amazon::S3::HTTPRequest;
$Net::Amazon::S3::HTTPRequest::VERSION = '0.97';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
use HTTP::Date;
use MIME::Base64 qw( encode_base64 );
use Moose::Util::TypeConstraints;
use URI::Escape qw( uri_escape_utf8 );
use URI::QueryParam;
use URI;

use Net::Amazon::S3::Signature::V2;

# ABSTRACT: Create a signed HTTP::Request

my $METADATA_PREFIX      = 'x-amz-meta-';
my $AMAZON_HEADER_PREFIX = 'x-amz-';

enum 'HTTPMethod' => [ qw(DELETE GET HEAD PUT POST) ];

with 'Net::Amazon::S3::Role::Bucket';
has '+bucket' => (required => 0);

has 's3'     => ( is => 'ro', isa => 'Net::Amazon::S3', required => 1 );
has 'method' => ( is => 'ro', isa => 'HTTPMethod',      required => 1 );
has 'path'   => ( is => 'ro', isa => 'Str',             required => 1 );
has 'headers' =>
	( is => 'ro', isa => 'HashRef', required => 0, default => sub { {} } );
has 'content' =>
	( is => 'ro', isa => 'Str|CodeRef|ScalarRef', required => 0, default => '' );
has 'metadata' =>
	( is => 'ro', isa => 'HashRef', required => 0, default => sub { {} } );
has use_virtual_host => (
	is => 'ro',
	isa => 'Bool',
	lazy => 1,
	default => sub { $_[0]->s3->use_virtual_host },
);
has authorization_method => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { $_[0]->s3->authorization_method },
);
has region => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	default => sub { $_[0]->bucket->region },
);

has request_uri => (
	is => 'ro',
	init_arg => undef,
	lazy => 1,
	builder => '_build_uri',
);

__PACKAGE__->meta->make_immutable;

sub _build_uri {
	my ($self) = @_;

	my $path = $self->path;

	my $protocol = $self->s3->secure ? 'https' : 'http';
	my $host = $self->s3->host;
	my $uri = "$protocol://$host/$path";

	if ($self->use_virtual_host) {
		# use https://bucketname.s3.amazonaws.com instead of https://s3.amazonaws.com/bucketname
		# see http://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html
		$uri =~ s{$host/(.*?)/}{$1.$host/};
	}

	return $uri;
}

# make the HTTP::Request object
sub _build_request {
	my $self     = shift;

	my $method   = $self->method;
	my $headers  = $self->headers;
	my $content  = $self->content;
	my $metadata = $self->metadata;

	my $http_headers = $self->_merge_meta( $headers, $metadata );
	my $uri          = $self->request_uri;

	my $http_request = HTTP::Request->new( $method, $uri, $http_headers, $content );
	$http_request->content_length (0) unless $http_request->content_length;

	return $http_request;
}

sub http_request {
	my $self     = shift;

	my $request = $self->_build_request;

	$self->authorization_method->new( http_request => $self )->sign_request( $request )
		unless $request->header( 'Authorization' );

	return $request;
}

sub query_string_authentication_uri {
	my ( $self, $expires ) = @_;

	my $request = $self->_build_request;
	my $sign = $self->authorization_method->new( http_request => $self );

	return $sign->sign_uri( $request, $expires );
}

sub _merge_meta {
	my ( $self, $headers, $metadata ) = @_;
	$headers  ||= {};
	$metadata ||= {};

	my $http_header = HTTP::Headers->new;
	while ( my ( $k, $v ) = each %$headers ) {
		$http_header->header( $k => $v );
	}
	while ( my ( $k, $v ) = each %$metadata ) {
		$http_header->header( "$METADATA_PREFIX$k" => $v );
	}

	return $http_header;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::HTTPRequest - Create a signed HTTP::Request

=head1 VERSION

version 0.97

=head1 SYNOPSIS

  my $http_request = Net::Amazon::S3::HTTPRequest->new(
    s3      => $self->s3,
    method  => 'PUT',
    path    => $self->bucket . '/',
    headers => $headers,
    content => $content,
  )->http_request;

=head1 DESCRIPTION

This module creates an HTTP::Request object that is signed
appropriately for Amazon S3.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 http_request

This method creates, signs and returns a HTTP::Request object.

=head2 query_string_authentication_uri

This method creates, signs and returns a query string authentication
URI.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
