package Net::Amazon::S3::Response;
# Abstract: Behaviour common to most S3 responses.
$Net::Amazon::S3::Response::VERSION = '0.94';
use Moose;

use Carp ();
use XML::LibXML;
use XML::LibXML::XPathContext;

use Net::Amazon::S3::Constants;

use namespace::clean;

has http_response => (
	is => 'ro',
	required => 1,
	handles => [
		qw[ code ],
		qw[ message ],
		qw[ is_success ],
		qw[ is_redirect ],
		qw[ status_line ],
		qw[ content ],
		qw[ decoded_content ],
		qw[ header ],
		qw[ headers ],
		qw[ header_field_names ],
	],
);

has xml_document => (
	is          => 'ro',
	init_arg    => undef,
	lazy        => 1,
	builder     => '_build_xml_document',
);

has xpath_context => (
   is          => 'ro',
   init_arg    => undef,
   lazy        => 1,
   builder     => '_build_xpath_context',
);

has error_code => (
	is          => 'ro',
	init_arg    => undef,
	lazy        => 1,
	builder     => '_build_error_code',
);

has error_message => (
	is          => 'ro',
	init_arg    => undef,
	lazy        => 1,
	builder     => '_build_error_message',
);

has error_resource => (
	is          => 'ro',
	init_arg    => undef,
	lazy        => 1,
	builder     => '_build_error_resource',
);

has error_request_id => (
	is          => 'ro',
	init_arg    => undef,
	lazy        => 1,
	builder     => '_build_error_request_id',
);

has _data => (
	is          => 'ro',
	init_arg    => undef,
	lazy        => 1,
	builder     => '_build_data',
);

sub _parse_data;

sub connection {
	return $_[0]->header ('Connection');
}

sub content_length {
	return $_[0]->http_response->content_length || 0;
}

sub content_type {
	return $_[0]->http_response->content_type;
}

sub date {
	return $_[0]->header ('Date');
}

sub etag {
	return $_[0]->_decode_etag ($_[0]->header ('ETag'));
}

sub server {
	return $_[0]->header ('Server');
}

sub delete_marker {
	return $_[0]->header (Net::Amazon::S3::Constants::HEADER_DELETE_MARKER);
}

sub id_2 {
	return $_[0]->header (Net::Amazon::S3::Constants::HEADER_ID_2);
}

sub request_id {
	return $_[0]->header (Net::Amazon::S3::Constants::HEADER_REQUEST_ID);
}

sub version_id {
	return $_[0]->header (Net::Amazon::S3::Constants::HEADER_VERSION_ID);
}

sub is_xml_content {
	my ($self) = @_;

	return $self->content_type =~ m:^application/xml\b: && $self->decoded_content;
}

sub is_error {
	my ($self) = @_;

	return 1 if $self->http_response->is_error;
	return 1 if $self->findvalue ('/Error');
	return;
}

sub is_internal_response {
	my ($self) = @_;

	my $header = $self->header ('Client-Warning');
	return !! ($header && $header eq 'Internal response');
}

sub findvalue {
	my ($self, @path) = @_;

	return '' unless $self->xpath_context;
	$self->xpath_context->findvalue (@path);
}

sub findnodes {
	my ($self, @path) = @_;

	return unless $self->xpath_context;
	$self->xpath_context->findnodes (@path);
}

sub _build_data {
	my ($self) = @_;

	return $self->is_success
		? $self->_parse_data
		: undef
		;
}
sub _build_error_code {
	my ($self) = @_;

	return
		unless $self->is_error;

	return $self->http_response->code
		unless $self->xpath_context;

	return $self->findvalue ('/Error/Code');
}

sub _build_error_message {
	my ($self) = @_;

	return
		unless $self->is_error;

	return $self->http_response->message
		unless $self->xpath_context;

	return $self->findvalue ('/Error/Message');
}

sub _build_error_resource {
	my ($self) = @_;

	return
		unless $self->is_error;

	return "${\ $self->http_response->request->uri }"
		unless $self->xpath_context;

	return $self->findvalue ('/Error/Resource');
}

sub _build_error_request_id {
	my ($self) = @_;

	return
		unless $self->is_error;

	return $self->request_id
		unless $self->xpath_context;

	return $self->findvalue ('/Error/RequestId');
}

sub _build_xml_document {
	my ($self) = @_;

	return unless $self->is_xml_content;

	# TODO: A 200 OK response can contain valid or invalid XML
	return XML::LibXML->new->parse_string ($self->http_response->decoded_content);
}

sub _build_xpath_context {
	my ($self) = @_;

	my $doc = $self->xml_document;
	return unless $doc;

	my $xpc = XML::LibXML::XPathContext->new ($doc);

	my $s3_ns = $doc->documentElement->lookupNamespaceURI
		|| 'http://s3.amazonaws.com/doc/2006-03-01/';
	$xpc->registerNs (s3 => $s3_ns);

	return $xpc;
}

sub _decode_etag {
	my ($self, $etag) = @_;

	$etag =~ s/ (?:^") | (?:"$) //gx;
	return $etag;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::Amazon::S3::Response

=head1 VERSION

version 0.94

=head1 SYNOPSIS

	package Command::Response;
	extends 'Net::Amazon::S3::Response';

	...
	my $response = Command::Response->new (
		http_response => $http_response,
	);

=head1 DESCRIPTION

Response handler base class providing functionality common to most S3 responses.

=head1 EXTENDING

L<Net::Amazon::S3::Response> provides methods to cache response data.

=over

=item _data

Read-only accessor initialized by C<_build_data>

=item _build_data

Data builder, by default calls C<_parse_data> if response is success and provides
valid XML document.

=item _parse_data

Abstract (undefined in parent) method to be implemented by children.

=back

=head1 METHODS

=head2 Constructor

Constructor accepts only one (required) parameter - C<http_response>.
It should act like L<HTTP::Response>.

=head2 Response classification methods

=over

=item is_success

True if response is a success response, false otherwise.

Successful response may contain invalid XML.

=item is_redirect

True if response is a redirect.

=item is_error

True if response is an error response, false otherwise.

Response is considered to be an error either when response code is an HTTP
error (4xx or 5xx) or response content is an error XML document.

See also L<"S3 Error Response"|https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html>
for more details.

=item is_internal_response

True if response is generated by user agent itself (eg: Cannot connect)

=item is_xml_content

True if response data is a valid XML document

=back

=head2 Error handling

Apart error classifition L<Net::Amazon::S3::Response> provides also common
error data accessors.

Error data are available only in case of error response.

=over

=item error_code

Either content of C<Error/Code> XML element or HTTP response code.

=item error_message

Either content of C<Error/Message> XML element or HTTP response message.

=item error_request_id

Content of C<Error/RequestId> XML element if available, C<x-amz-request-id> header
if available, empty list otherwise.

=item error_resource

Content of c<Error/Resource> if available, request uri otherwise.

=back

=head2 Common Response Headers

See L<"S3 Common Response Headers"|https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonResponseHeaders.html>
for more details.

=over

=item content_length

=item content_type

=item connection

=item etag

ETag with trimmed leading/trailing quotes.

=item server

=item delete_marker

=item request_id

=item id_2

=item version_id

=back

=head2 XML Document parsing

=over

=item xml_document

Lazy built instance of L<XML::LibXML>.

Available only if response is XML response and contains valid XML document.

=item xpath_context

Lazy built instance of L<XML::LibXML::XPathContext>.

Available only if response is XML response and contains valid XML document

=back

=head2 HTTP Response methods

Further methods delegated to C<http_response>.
Refer L<HTTP::Response> for description.

=over

=item code

=item message

=item status_line

=item content

=item decoded_content

=item header

=item headers

=item header_field_names

=back

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is part of L<Net::Amazon::S3>.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
