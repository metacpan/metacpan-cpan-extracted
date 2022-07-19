package Net::Amazon::S3::Client::Object;
$Net::Amazon::S3::Client::Object::VERSION = '0.991';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
use DateTime::Format::HTTP;
use Digest::MD5 qw(md5 md5_hex);
use Digest::MD5::File qw(file_md5 file_md5_hex);
use File::stat;
use MIME::Base64;
use Moose::Util::TypeConstraints;
use MooseX::Types::DateTime::MoreCoercions 0.07 qw( DateTime );
use IO::File 1.14;
use Ref::Util ();

# ABSTRACT: An easy-to-use Amazon S3 client object

use Net::Amazon::S3::Constraint::ACL::Canned;
use Net::Amazon::S3::Constraint::Etag;
use Net::Amazon::S3::Client::Object::Range;

with 'Net::Amazon::S3::Role::ACL';

enum 'StorageClass' =>
	# Current list at https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html#AmazonS3-PutObject-request-header-StorageClass
	[ qw(standard reduced_redundancy standard_ia onezone_ia intelligent_tiering glacier deep_archive) ];

has 'client' =>
	( is => 'ro', isa => 'Net::Amazon::S3::Client', required => 1 );
has 'bucket' =>
	( is => 'ro', isa => 'Net::Amazon::S3::Client::Bucket', required => 1 );
has 'key'  => ( is => 'ro', isa => 'Str',  required => 1 );
has 'etag' => ( is => 'ro', isa => 'Net::Amazon::S3::Constraint::Etag', required => 0 );
has 'size' => ( is => 'ro', isa => 'Int',  required => 0 );
has 'last_modified' =>
	( is => 'ro', isa => DateTime, coerce => 1, required => 0, default => sub { shift->last_modified_raw }, lazy => 1 );
has 'last_modified_raw' =>
	( is => 'ro', isa => 'Str', required => 0 );
has 'expires' => ( is => 'rw', isa => DateTime, coerce => 1, required => 0 );
has 'content_type' => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
	default  => 'binary/octet-stream'
);
has 'content_disposition' => (
	is => 'ro',
	isa => 'Str',
	required => 0,
);
has 'content_encoding' => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
);
has 'cache_control' => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
);
has 'storage_class' => (
	is       => 'ro',
	isa      => 'StorageClass',
	required => 0,
	default  => 'standard',
);
has 'user_metadata' => (
	is       => 'ro',
	isa      => 'HashRef',
	required => 0,
	default  => sub { {} },
);
has 'website_redirect_location' => (
	is       => 'ro',
	isa      => 'Str',
	required => 0,
);
has 'encryption' => (
	is       => 'ro',
	isa      => 'Maybe[Str]',
	required => 0,
);

__PACKAGE__->meta->make_immutable;

sub range {
	my ($self, $range) = @_;

	return Net::Amazon::S3::Client::Object::Range->new (
		object  => $self,
		range   => $range,
	);
}

sub exists {
	my $self = shift;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Head',
	);

	return $response->is_success;
}

sub _get {
	my $self = shift;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Fetch',

		method => 'GET',
	);

	$self->_load_user_metadata ($response->http_response);

	return $response;
}

sub get {
	my $self = shift;
	return $self->_get->content;
}

sub get_decoded {
	my $self = shift;
	return $self->_get->decoded_content(@_);
}

sub get_callback {
	my ( $self, $callback ) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Fetch',
		filename       => $callback,
		method => 'GET',
	);

	return $response->http_response;
}

sub get_filename {
	my ( $self, $filename ) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Fetch',
		filename       => $filename,
		method => 'GET',
	);

	$self->_load_user_metadata($response->http_response);
}

sub _load_user_metadata {
	my ( $self, $http_response ) = @_;

	my %user_metadata;
	for my $header_name ($http_response->header_field_names) {
		my ($metadata_name) = lc($header_name) =~ /\A x-amz-meta- (.*) \z/xms
			or next;
		$user_metadata{$metadata_name} = $http_response->header($header_name);
	}

	%{ $self->user_metadata } = %user_metadata;
}

sub put {
	my ( $self, $value ) = @_;
	$self->_put( $value, length $value, md5_hex($value) );
}

sub _put {
	my ( $self, $value, $size, $md5_hex ) = @_;

	my $md5_base64 = encode_base64( pack( 'H*', $md5_hex ) );
	chomp $md5_base64;

	my $conf = {
		'Content-MD5'    => $md5_base64,
		'Content-Length' => $size,
		'Content-Type'   => $self->content_type,
	};

	if ( $self->expires ) {
		$conf->{Expires}
			= DateTime::Format::HTTP->format_datetime( $self->expires );
	}
	if ( $self->content_encoding ) {
		$conf->{'Content-Encoding'} = $self->content_encoding;
	}
	if ( $self->content_disposition ) {
		$conf->{'Content-Disposition'} = $self->content_disposition;
	}
	if ( $self->cache_control ) {
		$conf->{'Cache-Control'} = $self->cache_control;
	}
	if ( $self->storage_class && $self->storage_class ne 'standard' ) {
		$conf->{'x-amz-storage-class'} = uc $self->storage_class;
	}
	if ( $self->website_redirect_location ) {
		$conf->{'x-amz-website-redirect-location'} = $self->website_redirect_location;
	}
	$conf->{"x-amz-meta-\L$_"} = $self->user_metadata->{$_}
		for keys %{ $self->user_metadata };

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Add',

		value      => $value,
		headers    => $conf,
		acl        => $self->acl,
		encryption => $self->encryption,
	);

	my $http_response = $response->http_response;

	confess 'Error uploading ' . $http_response->as_string
		unless $http_response->is_success;

	return '';
}

sub put_filename {
	my ( $self, $filename ) = @_;

	my $md5_hex = $self->etag || file_md5_hex($filename);
	my $size = $self->size;
	unless ($size) {
		my $stat = stat($filename) || confess("No $filename: $!");
		$size = $stat->size;
	}

	$self->_put( $self->_content_sub($filename), $size, $md5_hex );
}

sub delete {
	my $self = shift;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Delete',
	);

	return $response->is_success;
}

sub set_acl {
	my ($self, %params) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Acl::Set',
		%params,
	);

	return $response->is_success;
}

sub add_tags {
	my ($self, %params) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Tags::Add',
		%params,
	);

	return $response->is_success;
}

sub delete_tags {
	my ($self, %params) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Tags::Delete',

		(version_id => $params{version_id}) x!! defined $params{version_id},
	);

	return $response->is_success;
}

sub initiate_multipart_upload {
	my $self = shift;
	my %args = ref($_[0]) ? %{$_[0]} : @_;

	$args{acl} = $args{acl_short} if exists $args{acl_short};
	delete $args{acl_short};
	$args{acl} = $self->acl unless $args{acl};

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Upload::Create',

		encryption => $self->encryption,
		($args{acl}       ? (acl       => $args{acl})     : ()),
		($args{headers}   ? (headers   => $args{headers}) : ()),
	);

	return unless $response->is_success;

	confess "Couldn't get upload id from initiate_multipart_upload response XML"
		unless $response->upload_id;

	return $response->upload_id;
}

sub complete_multipart_upload {
	my $self = shift;

	my %args = ref($_[0]) ? %{$_[0]} : @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Upload::Complete',

		upload_id    => $args{upload_id},
		etags        => $args{etags},
		part_numbers => $args{part_numbers},
	);

	return $response->http_response;
}

sub abort_multipart_upload {
	my $self = shift;

	my %args = ref($_[0]) ? %{$_[0]} : @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Upload::Abort',

		upload_id => $args{upload_id},
	);

	return $response->http_response;
}


sub put_part {
	my $self = shift;

	my %args = ref($_[0]) ? %{$_[0]} : @_;

	#work out content length header
	$args{headers}->{'Content-Length'} = length $args{value}
		if(defined $args{value});

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Upload::Part',

		upload_id   => $args{upload_id},
		part_number => $args{part_number},
		acl_short   => $args{acl_short},
		copy_source => $args{copy_source},
		headers     => $args{headers},
		value       => $args{value},
	);

	return $response->http_response;
}

sub list_parts {
	confess "Not implemented";
	# TODO - Net::Amazon::S3::Request:ListParts is implemented, but need to
	# define better interface at this level. Currently returns raw XML.
}

sub uri {
	my $self = shift;
	return Net::Amazon::S3::Operation::Object::Fetch::Request->new (
		s3     => $self->client->s3,
		bucket => $self->bucket->name,
		key    => $self->key,
		method => 'GET',
	)->http_request->uri;
}

sub query_string_authentication_uri {
	my ($self, $query_form) = @_;
	return $self->query_string_authentication_uri_for_method (GET => $query_form);
}

sub query_string_authentication_uri_for_method {
	my ($self, $method, $query_form) = @_;
	return Net::Amazon::S3::Operation::Object::Fetch::Request->new (
		s3     => $self->client->s3,
		bucket => $self->bucket->name,
		key    => $self->key,
		method => $method,
	)->query_string_authentication_uri ($self->expires->epoch, $query_form);
}

sub head {
	my $self = shift;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Fetch',

		key    => $self->key,
		method => 'HEAD',
	);

	return unless $
		response->is_success;
	my $http_response = $response->http_response;

	my %metadata;
	for my $header_name ($http_response->header_field_names) {
		if ($self->_is_metadata_header ($header_name)) {
			my $metadata_name = $self->_format_metadata_name ($header_name);
			$metadata{$metadata_name} = $http_response->header ($header_name);
		}
	}

	return \%metadata;
}

sub _is_metadata_header {
	my (undef, $header) = @_;
	$header = lc($header);

	my %valid_metadata_headers = map +($_ => 1), (
		'accept-ranges',
		'cache-control',
		'etag',
		'expires',
		'last-modified',
	);

	return 1 if exists $valid_metadata_headers{$header};
	return 1 if $header =~ m/^x-amz-(?!id-2$)/;
	return 1 if $header =~ m/^content-/;
	return 0;
}

sub _format_metadata_name {
	my (undef, $header) = @_;
	$header = lc($header);
	$header =~ s/^x-amz-//;

	my $metadata_name = join('', map (ucfirst, split(/-/, $header)));
	$metadata_name = 'ETag' if ($metadata_name eq 'Etag');

	return $metadata_name;
}

sub available {
	my $self = shift;

	my %metadata = %{$self->head};

	# An object is available if:
	# - the storage class isn't GLACIER;
	# - the storage class is GLACIER and the object was fully restored (Restore: ongoing-request="false");
	my $glacier = (exists($metadata{StorageClass}) and $metadata{StorageClass} eq 'GLACIER') ? 1 : 0;
	my $restored = (exists($metadata{Restore}) and $metadata{Restore} =~ m/ongoing-request="false"/) ? 1 : 0;
	return (!$glacier or $restored) ? 1 :0;
}

sub restore {
	my $self = shift;
	my (%conf) = @_;

	my $request = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Restore',

		key    => $self->key,
		days   => $conf{days},
		tier   => $conf{tier},
	);

	return $request->http_response;
}

sub _content_sub {
	my $self      = shift;
	my $filename  = shift;
	my $stat      = stat($filename);
	my $remaining = $stat->size;
	my $blksize   = $stat->blksize || 4096;

	confess "$filename not a readable file with fixed size"
		unless -r $filename and ( -f _ || $remaining );
	my $fh = IO::File->new( $filename, 'r' )
		or confess "Could not open $filename: $!";
	$fh->binmode;

	return sub {
		my $buffer;

		# upon retries the file is closed and we must reopen it
		unless ( $fh->opened ) {
			$fh = IO::File->new( $filename, 'r' )
				or confess "Could not open $filename: $!";
			$fh->binmode;
			$remaining = $stat->size;
		}

		# warn "read remaining $remaining";
		unless ( my $read = $fh->read( $buffer, $blksize ) ) {

#                       warn "read $read buffer $buffer remaining $remaining";
			confess
				"Error while reading upload content $filename ($remaining remaining) $!"
				if $! and $remaining;

			# otherwise, we found EOF
			$fh->close
				or confess "close of upload content $filename failed: $!";
			$buffer ||= ''
				;    # LWP expects an emptry string on finish, read returns 0
		}
		$remaining -= length($buffer);
		return $buffer;
	};
}

sub _is_multipart_etag {
	my ( $self, $etag ) = @_;
	return 1 if($etag =~ /\-\d+$/);
}

sub _perform_operation {
	my ($self, $operation, %params) = @_;

	$self->bucket->_perform_operation ($operation => (
		key => $self->key,
		%params,
	));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Client::Object - An easy-to-use Amazon S3 client object

=head1 VERSION

version 0.991

=head1 SYNOPSIS

  # show the key
  print $object->key . "\n";

  # show the etag of an existing object (if fetched by listing
  # a bucket)
  print $object->etag . "\n";

  # show the size of an existing object (if fetched by listing
  # a bucket)
  print $object->size . "\n";

  # to create a new object
  my $object = $bucket->object( key => 'this is the key' );
  $object->put('this is the value');

  # to get the value of an object
  my $value = $object->get;

  # to get the metadata of an object
  my %metadata = %{$object->head};

  # to see if an object exists
  if ($object->exists) { ... }

  # to delete an object
  $object->delete;

  # to create a new object which is publically-accessible with a
  # content-type of text/plain which expires on 2010-01-02
  my $object = $bucket->object(
    key          => 'this is the public key',
    acl          => Net::Amazon::S3::ACL::CANNED->PUBLIC_READ,
    content_type => 'text/plain',
    expires      => '2010-01-02',
  );
  $object->put('this is the public value');

  # return the URI of a publically-accessible object
  my $uri = $object->uri;

  # to view if an object is available for downloading
  # Basically, the storage class isn't GLACIER or the object was
  # fully restored
  $object->available;

  # to restore an object on a GLACIER storage class
  $object->restore(
    days => 1,
    tier => 'Standard',
  );

  # to store a new object with server-side encryption enabled
  my $object = $bucket->object(
    key        => 'my secret',
    encryption => 'AES256',
  );
  $object->put('this data will be stored using encryption.');

  # upload a file
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    content_type => 'image/jpeg',
  );
  $object->put_filename('hat.jpg');

  # upload a file if you already know its md5_hex and size
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    content_type => 'image/jpeg',
    etag         => $md5_hex,
    size         => $size,
  );
  $object->put_filename('hat.jpg');

  # download the value of the object into a file
  my $object = $bucket->object( key => 'images/my_hat.jpg' );
  $object->get_filename('hat_backup.jpg');

  # use query string authentication for object fetch
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    expires      => '2009-03-01',
  );
  my $uri = $object->query_string_authentication_uri();

	# use query string authentication for object upload
	my $object = $bucket->object(
		key          => 'images/my_hat.jpg',
		expires      => '2009-03-01',
	);
	my $uri = $object->query_string_authentication_uri_for_method('PUT');

=head1 DESCRIPTION

This module represents objects in buckets.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 range

	my $value = $object->range ('bytes=1024-10240')->get;

Provides simple interface to ranged download. See also L<Net::Amazon::S3::Client::Object::Range>.

=head2 etag

  # show the etag of an existing object (if fetched by listing
  # a bucket)
  print $object->etag . "\n";

=head2 delete

  # to delete an object
  $object->delete;

=head2 exists

  # to see if an object exists
  if ($object->exists) { ... }

Method doesn't report error when bucket or key doesn't exist.

=head2 get

  # to get the vaue of an object
  my $value = $object->get;

=head2 head

  # to get the metadata of an object
  my %metadata = %{$object->head};

Unlike C<exists> this method does report error.

=head2 get_decoded

  # get the value of an object, and decode any Content-Encoding and/or
  # charset; see decoded_content in HTTP::Response
  my $value = $object->get_decoded;

=head2 get_filename

  # download the value of the object into a file
  my $object = $bucket->object( key => 'images/my_hat.jpg' );
  $object->get_filename('hat_backup.jpg');

=head2 last_modified, last_modified_raw

  # get the last_modified data as DateTime (slow)
  my $dt = $obj->last_modified;
  # or raw string in form '2015-05-15T10:12:40.000Z' (fast)
  # use this form if you are working with thousands of objects and
  # do not actually need an expensive DateTime for each of them
  my $raw = $obj->last_modified_raw;

=head2 key

  # show the key
  print $object->key . "\n";

=head2 available

  # to view if an object is available for downloading
  # Basically, the storage class isn't GLACIER or the object was
  # fully restored
  $object->available;

=head2 restore

  # to restore an object on a GLACIER storage class
  $object->restore(
    days => 1,
    tier => 'Standard',
  );

=head2 put

  # to create a new object
  my $object = $bucket->object( key => 'this is the key' );
  $object->put('this is the value');

  # to create a new object which is publically-accessible with a
  # content-type of text/plain
  my $object = $bucket->object(
    key          => 'this is the public key',
    acl          => 'public-read',
    content_type => 'text/plain',
  );
  $object->put('this is the public value');

For C<acl> refer L<Net::Amazon::S3::ACL>.

You may also set Content-Encoding using C<content_encoding>, and
Content-Disposition using C<content_disposition>.

You may specify the S3 storage class by setting C<storage_class> to either
C<standard>, C<reduced_redundancy>, C<standard_ia>, C<onezone_ia>,
C<intelligent_tiering>, C<glacier>, or C<deep_archive>; the default
is C<standard>.

You may set website-redirect-location object metadata by setting
C<website_redirect_location> to either another object name in the same
bucket, or to an external URL.

=head2 put_filename

  # upload a file
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    content_type => 'image/jpeg',
  );
  $object->put_filename('hat.jpg');

  # upload a file if you already know its md5_hex and size
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    content_type => 'image/jpeg',
    etag         => $md5_hex,
    size         => $size,
  );
  $object->put_filename('hat.jpg');

You may also set Content-Encoding using C<content_encoding>, and
Content-Disposition using C<content_disposition>.

You may specify the S3 storage class by setting C<storage_class> to either
C<standard>, C<reduced_redundancy>, C<standard_ia>, C<onezone_ia>,
C<intelligent_tiering>, C<glacier>, or C<deep_archive>; the default
is C<standard>.

You may set website-redirect-location object metadata by setting
C<website_redirect_location> to either another object name in the same
bucket, or to an external URL.

User metadata may be set by providing a non-empty hashref as
C<user_metadata>.

=head2 query_string_authentication_uri

  # use query string authentication, forcing download with custom filename
  my $object = $bucket->object(
    key          => 'images/my_hat.jpg',
    expires      => '2009-03-01',
  );
  my $uri = $object->query_string_authentication_uri({
    'response-content-disposition' => 'attachment; filename=abc.doc',
  });

=head2 query_string_authentication_uri_for_method

	my $uri = $object->query_string_authentication_uri_for_method ('PUT');

Similar to L</query_string_authentication_uri> but creates presigned uri
for specified HTTP method (Signature V4 uses also HTTP method).

Methods providee authenticated uri only for direct object operations.

See L<https://docs.aws.amazon.com/AmazonS3/latest/dev/PresignedUrlUploadObject.html>

=head2 size

  # show the size of an existing object (if fetched by listing
  # a bucket)
  print $object->size . "\n";

=head2 uri

  # return the URI of a publically-accessible object
  my $uri = $object->uri;

=head2 initiate_multipart_upload

	#initiate a new multipart upload for this object
	my $object = $bucket->object(
		key         => 'massive_video.avi',
		acl         => ...,
	);
	my $upload_id = $object->initiate_multipart_upload;

For description of C<acl> refer C<Net::Amazon::S3::ACL>.

=head2 put_part

  #add a part to a multipart upload
  my $put_part_response = $object->put_part(
     upload_id      => $upload_id,
     part_number    => 1,
     value          => $chunk_content,
  );
  my $part_etag = $put_part_response->header('ETag')

  Returns an L<HTTP::Response> object. It is necessary to keep the ETags for
  each part, as these are required to complete the upload.

=head2 complete_multipart_upload

  #complete a multipart upload
  $object->complete_multipart_upload(
    upload_id       => $upload_id,
    etags           => [$etag_1, $etag_2],
    part_numbers    => [$part_number_1, $part_number2],
  );

  The etag and part_numbers parameters are ordered lists specifying the part
  numbers and ETags for each individual part of the multipart upload.

=head2 user_metadata

  my $object = $bucket->object(key => $key);
  my $content = $object->get; # or use $object->get_filename($filename)

  # return the user metadata downloaded, as a hashref
  my $user_metadata = $object->user_metadata;

To upload an object with user metadata, set C<user_metadata> at construction
time to a hashref, with no C<x-amz-meta-> prefixes on the key names.  When
downloading an object, the C<get>, C<get_decoded> and C<get_filename>
ethods set the contents of C<user_metadata> to the same format.

=head2 add_tags

	$object->add_tags (
		tags        => { tag1 => 'val1', tag2 => 'val2' },
	);

	$object->add_tags (
		tags        => { tag1 => 'val1', tag2 => 'val2' },
		version_id  => $version_id,
	);

=head2 delete_tags

	$object->delete_tags;

	$object->delete_tags (
		version_id  => $version_id,
	);

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
