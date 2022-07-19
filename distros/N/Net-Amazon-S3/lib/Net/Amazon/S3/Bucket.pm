package Net::Amazon::S3::Bucket;
# ABSTRACT: convenience object for working with Amazon S3 buckets
$Net::Amazon::S3::Bucket::VERSION = '0.991';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
use Carp;
use File::stat;
use IO::File 1.14;

has 'account' => (
	is => 'ro',
	isa => 'Net::Amazon::S3',
	required => 1,
	handles => [qw[ err errstr ]],
);
has 'bucket'  => ( is => 'ro', isa => 'Str',             required => 1 );
has 'creation_date' => ( is => 'ro', isa => 'Maybe[Str]', required => 0 );

has 'region' => (
	is => 'ro',
	lazy => 1,
	predicate => 'has_region',
	default => sub {
		return $_[0]->account->vendor->guess_bucket_region ($_[0]);
	},
);

__PACKAGE__->meta->make_immutable;

# returns bool
sub add_key {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_, ['key', 'value']);

	my $key = delete $args{key};
	my $value = delete $args{value};

	if ( ref($value) eq 'SCALAR' ) {
		$args{'Content-Length'} ||= -s $$value;
		$value = _content_sub($$value);
	} else {
		$args{'Content-Length'} ||= length $value;
	}

	my $acl;
	$acl = delete $args{acl_short} if exists $args{acl_short};
	$acl = delete $args{acl}       if exists $args{acl};

	my $encryption = delete $args{encryption};
	my %headers = %args;

	# we may get a 307 redirect; ask server to signal 100 Continue
	# before reading the content from CODE reference (_content_sub)
	$headers{expect} = '100-continue' if ref $value;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Add',

		key       => $key,
		value     => $value,
		(acl      => $acl) x!! defined $acl,
		((encryption => $encryption) x!! defined $encryption),
		headers   => \%headers,
	);

	return $response->is_success;
}

sub add_key_filename {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_, ['key', 'value']);
	$args{value} = \ delete $args{value};

	return $self->add_key (%args);
}

sub copy_key {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_, ['key', 'source' ]);

	my $key = delete $args{key};
	my $source = delete $args{source};

	my $acl_short;
	if (%args) {
		if ( $args{acl_short} ) {
			$acl_short = $args{acl_short};
			delete $args{acl_short};
		}
		$args{Net::Amazon::S3::Constants->HEADER_METADATA_DIRECTIVE} ||= 'REPLACE';
	}

	$args{Net::Amazon::S3::Constants->HEADER_COPY_SOURCE} = $source;

	my $encryption = delete $args{encryption};

	my $acct    = $self->account;
	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Add',

		value     => '',
		key       => $key,
		acl_short => $acl_short,
		(encryption => $encryption) x!! defined $encryption,
		headers   => \%args,
	);

	return unless $response->is_success;
}

sub edit_metadata {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_object (\@_);

	my $key = delete $args{key};
	croak "Need some metadata to change" unless %args;

	return $self->copy_key (
		key    => $key,
		source => "/" . $self->bucket . "/" . $key,
		%args,
	);
}

sub head_key {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_object (\@_);

	return $self->get_key (%args, method => 'HEAD', filename => undef);
}

sub query_string_authentication_uri {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_, ['key', 'expires_at']);

	$args{method} = 'GET' unless exists $args{method};

	my $request = Net::Amazon::S3::Operation::Object::Fetch::Request->new (
		s3     => $self->account,
		bucket => $self,
		key    => $args{key},
		method => $args{method},
	);

	return $request->query_string_authentication_uri ($args{expires_at});
}

sub get_key {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_, ['key', 'method', 'filename']);

	$args{filename} = ${ delete $args{filename} }
		if ref $args{filename};

	$args{method} ||= 'GET';

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Fetch',

		filename => $args{filename},
		(range   => $args{range}) x defined $args{range},

		key    => $args{key},
		method => $args{method},
	);

	return unless $response->is_success;
	my $etag = $response->etag;

	my $return;
	foreach my $header ($response->headers->header_field_names) {
		$return->{ lc $header } = $response->header ($header);
	}
	$return->{content_length} = $response->content_length || 0;
	$return->{content_type}   = $response->content_type;
	$return->{etag}           = $etag;
	$return->{value}          = $response->content;

	return $return;

}

sub get_key_filename {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_, ['key', 'method', 'filename']);

	$args{filename} = \ delete $args{filename};
	return $self->get_key (%args);
}

# returns bool
sub delete_multi_object {
	my $self = shift;
	my @objects = @_;
	return unless( scalar(@objects) );

	# Since delete can handle up to 1000 requests, be a little bit nicer
	# and slice up requests and also allow keys to be strings
	# rather than only objects.
	my $last_result;
	while (scalar(@objects) > 0) {
		my $response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Objects::Delete',

			keys    => [
				map { ref ($_) ? $_->key : $_ }
				splice @objects, 0, ((scalar(@objects) > 1000) ? 1000 : scalar(@objects))
			]
		);

		return unless $response->is_success;
	}

	return 1;
}

sub delete_key {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_object (\@_);

	croak 'must specify key' unless defined $args{key} && length $args{key};

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Object::Delete',
		%args,
	);

	return $response->is_success;
}

sub delete_bucket {
	my $self = shift;
	return $self->account->delete_bucket (bucket => $self, @_);
}

sub list {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_);

	return $self->account->list_bucket ($self, %args);
}

sub list_all {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_);

	return $self->account->list_bucket_all ($self, %args);
}

sub get_acl {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_object (\@_);

	my $response;
	if (defined $args{key}) {
		$response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Object::Acl::Fetch',
			%args,
		);
	} else {
		delete $args{key};
		$response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Bucket::Acl::Fetch',
			%args,
		);
	}

	return unless $response->is_success;
	return $response->content;
}

sub set_acl {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_object (\@_);

	my $response;
	if (defined $args{key}) {
		$response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Object::Acl::Set',
			%args,
		);
	} else {
		delete $args{key};
		$response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Bucket::Acl::Set',
			%args,
		);
	}

	return unless $response->is_success;
	return 1;
}

sub get_location_constraint {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments (\@_);

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Location',
		%args,
	);

	return unless $response->is_success;
	return $response->location;
}

sub add_tags {
	my $self = shift;
	my %args = @_ == 1 ? %{ $_[0] } : @_;

	my $response;
	if (defined $args{key}) {
		$response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Object::Tags::Add',
			%args,
		);
	} else {
		delete $args{key};
		$response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Bucket::Tags::Add',
			%args,
		);
	}

	return $response->is_success;
}

sub delete_tags {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_object (\@_);

	my $response;
	if (defined $args{key}) {
		$response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Object::Tags::Delete',
			%args,
		);
	} else {
		delete $args{key};
		$response = $self->_perform_operation (
			'Net::Amazon::S3::Operation::Bucket::Tags::Delete',
			%args,
		);
	}

	return $response->is_success;
}

sub _content_sub {
	my $filename  = shift;
	my $stat      = stat($filename);
	my $remaining = $stat->size;
	my $blksize   = $stat->blksize || 4096;

	croak "$filename not a readable file with fixed size"
		unless -r $filename and ( -f _ || $remaining );
	my $fh = IO::File->new( $filename, 'r' )
		or croak "Could not open $filename: $!";
	$fh->binmode;

	return sub {
		my $buffer;

		# upon retries the file is closed and we must reopen it
		unless ( $fh->opened ) {
			$fh = IO::File->new( $filename, 'r' )
				or croak "Could not open $filename: $!";
			$fh->binmode;
			$remaining = $stat->size;
		}

		# warn "read remaining $remaining";
		unless ( my $read = $fh->read( $buffer, $blksize ) ) {

#                       warn "read $read buffer $buffer remaining $remaining";
			croak
				"Error while reading upload content $filename ($remaining remaining) $!"
				if $! and $remaining;

			# otherwise, we found EOF
			$fh->close
				or croak "close of upload content $filename failed: $!";
			$buffer ||= ''
				;    # LWP expects an emptry string on finish, read returns 0
		}
		$remaining -= length($buffer);
		return $buffer;
	};
}

sub _head_region {
	my ($self) = @_;

	my $protocol = $self->account->secure ? 'https' : 'http';
	my $host = $self->account->host;
	my $path = $self->bucket;
	my @retry = (1, 2, (4) x 8);

	if ($self->account->use_virtual_host) {
		$host = "$path.$host";
		$path = '';
	}

	my $request_uri = "${protocol}://${host}/$path";
	while (@retry) {
		my $request = HTTP::Request->new (HEAD => $request_uri);

		# Disable redirects
		my $requests_redirectable = $self->account->ua->requests_redirectable;
		$self->account->ua->requests_redirectable( [] );

		my $response = $self->account->ua->request ($request);

		$self->account->ua->requests_redirectable( $requests_redirectable );

		return $response->header (Net::Amazon::S3::Constants->HEADER_BUCKET_REGION)
			if $response->header (Net::Amazon::S3::Constants->HEADER_BUCKET_REGION);

		print STDERR "Invalid bucket head response; $request_uri\n";
		print STDERR $response->as_string;

		sleep shift @retry;
	}

	die "Cannot determine bucket region; bucket=${\ $self->bucket }";
}

sub _perform_operation {
	my ($self, $operation, %params) = @_;

	$self->account->_perform_operation ($operation => (
		bucket => $self,
		%params,
	));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Bucket - convenience object for working with Amazon S3 buckets

=head1 VERSION

version 0.991

=head1 SYNOPSIS

  use Net::Amazon::S3;

  my $bucket = $s3->bucket("foo");

  ok($bucket->add_key("key", "data"));
  ok($bucket->add_key("key", "data", {
     content_type => "text/html",
    'x-amz-meta-colour' => 'orange',
  }));

  # Enable server-side encryption
  ok($bucket->add_key("key", "data", {
     encryption => 'AES256',
  }));

  # the err and errstr methods just proxy up to the Net::Amazon::S3's
  # objects err/errstr methods.
  $bucket->add_key("bar", "baz") or
      die $bucket->err . $bucket->errstr;

  # fetch a key
  $val = $bucket->get_key("key");
  is( $val->{value},               'data' );
  is( $val->{content_type},        'text/html' );
  is( $val->{etag},                'b9ece18c950afbfa6b0fdbfa4ff731d3' );
  is( $val->{'x-amz-meta-colour'}, 'orange' );

  # fetch a part of the key
  $val = $bucket->get_key("key", { range => "bytes=1024-10240" });

  # returns undef on missing or on error (check $bucket->err)
  is(undef, $bucket->get_key("non-existing-key"));
  die $bucket->errstr if $bucket->err;

  # fetch a key's metadata
  $val = $bucket->head_key("key");
  is( $val->{value},               '' );
  is( $val->{content_type},        'text/html' );
  is( $val->{etag},                'b9ece18c950afbfa6b0fdbfa4ff731d3' );
  is( $val->{'x-amz-meta-colour'}, 'orange' );

  # delete a key
  ok($bucket->delete_key($key_name));
  ok(! $bucket->delete_key("non-exist-key"));

  # delete the entire bucket (Amazon requires it first be empty)
  $bucket->delete_bucket;

=head1 DESCRIPTION

This module represents an S3 bucket.  You get a bucket object
from the Net::Amazon::S3 object.

=head1 METHODS

=head2 new

Create a new bucket object. Expects a hash containing these two arguments:

=over

=item bucket

=item account

=back

=head2 add_key

Takes three positional parameters:

=over

=item key

=item value

=item configuration

A hash of configuration data for this key.

=over

=item acl

=item encryption

=item any additional HTTP header

=back

See L<Net::Amazon::S3::Operation::Object::Add::Request> for details

=back

Returns a boolean.

=head2 add_key_filename

Use this to upload a large file to S3. Takes three positional parameters:

=over

=item key

=item filename

=item configuration

A hash of configuration data for this key. (See synopsis);

=back

Returns a boolean.

=head2 copy_key

Creates (or replaces) a key, copying its contents from another key elsewhere in S3.
Takes the following parameters:

=over

=item key

The key to (over)write

=item source

Where to copy the key from. Should be in the form C</I<bucketname>/I<keyname>>/.

=item conf

Optional configuration hash. If present and defined, the configuration (ACL
and headers) there will be used for the new key; otherwise it will be copied
from the source key.

=back

=head2 edit_metadata

Changes the metadata associated with an existing key. Arguments:

=over

=item key

The key to edit

=item conf

The new configuration hash to use

=back

=head2 head_key KEY

Takes the name of a key in this bucket and returns its configuration hash

=head2 query_string_authentication_uri KEY, EXPIRES_AT

	my $uri = $bucket->query_string_authentication_uri (
		key => 'foo',
		expires_at => time + 3_600, # valid for one hour
	);

	my $uri = $bucket->query_string_authentication_uri (
		key => 'foo',
		expires_at => time + 3_600,
		method => 'PUT',
	);

Returns uri presigned with your credentials.

When used with Signature V4 you have to specify also HTTP method this
presigned uri will be used for (default: C<GET>)

Method provides authenticated uri only for direct object operations.

Method follows API's L</"CALLING CONVENTION">.

Recognized positional arguments (mandatory).

=over

=item key

=item expires_at

Expiration time (epoch time).

=back

Optional arguments

=over

=item method

Default: C<GET>

Intended HTTP method this uri will be presigned for.

Signature V2 doesn't use it but Signature V4 does.

See L<https://docs.aws.amazon.com/AmazonS3/latest/dev/PresignedUrlUploadObject.html>

=back

=head2 get_key $key_name [$method]

Takes a key name and an optional HTTP method (which defaults to C<GET>.
Fetches the key from AWS.

On failure:

Returns undef on missing content, throws an exception (dies) on server errors.

On success:

Returns a hashref of { content_type, etag, value, @meta } on success. Other
values from the server are there too, with the key being lowercased.

=head2 get_key_filename $key_name $method $filename

Use this to download large files from S3. Takes a key name and an optional
HTTP method (which defaults to C<GET>. Fetches the key from AWS and writes
it to the filename. THe value returned will be empty.

On failure:

Returns undef on missing content, throws an exception (dies) on server errors.

On success:

Returns a hashref of { content_type, etag, value, @meta } on success

=head2 delete_key $key_name

Removes C<$key> from the bucket. Forever. It's gone after this.

Returns true on success and false on failure

=head2 delete_bucket

Delete the current bucket object from the server. Takes no arguments.

Fails if the bucket has anything in it.

This is an alias for C<< $s3->delete_bucket($bucket) >>

=head2 list

List all keys in this bucket.

see L<Net::Amazon::S3/list_bucket> for documentation of this method.

=head2 list_all

List all keys in this bucket without having to worry about
'marker'. This may make multiple requests to S3 under the hood.

see L<Net::Amazon::S3/list_bucket_all> for documentation of this method.

=head2 get_acl

Takes one optional positional parameter

=over

=item key (optional)

If no key is specified, it returns the acl for the bucket.

=back

Returns an acl in XML format.

=head2 set_acl

Takes a configuration hash_ref containing:

=over

=item acl_xml (cannot be used in conjunction with acl_short)

An XML string which contains access control information which matches
Amazon's published schema.  There is an example of one of these XML strings
in the tests for this module.

=item acl_short (cannot be used in conjunction with acl_xml)

You can use the shorthand notation instead of specifying XML for
certain 'canned' types of acls.

(from the Amazon API documentation)

private: Owner gets FULL_CONTROL. No one else has any access rights.
This is the default.

public-read:Owner gets FULL_CONTROL and the anonymous principal is granted
READ access. If this policy is used on an object, it can be read from a
browser with no authentication.

public-read-write:Owner gets FULL_CONTROL, the anonymous principal is
granted READ and WRITE access. This is a useful policy to apply to a bucket,
if you intend for any anonymous user to PUT objects into the bucket.

authenticated-read:Owner gets FULL_CONTROL, and any principal authenticated
as a registered Amazon S3 user is granted READ access.

=item key (optional)

If the key is not set, it will apply the acl to the bucket.

=back

Returns a boolean.

=head2 get_location_constraint

Retrieves the location constraint set when the bucket was created. Returns a
string (eg, 'EU'), or undef if no location constraint was set.

=head2 err

The S3 error code for the last error the object ran into

=head2 errstr

A human readable error string for the last error the object ran into

=head2 add_tags

	# Add tags for a bucket
	$s3->add_tags ({
		bucket => 'bucket-name',
		tags   => { tag1 => 'value-1', tag2 => 'value-2' },
	});

	# Add tags for an object
	$s3->add_tags ({
		bucket => 'bucket-name',
		key    => 'key',
		tags   => { tag1 => 'value-1', tag2 => 'value-2' },
	});

Takes configuration parameters

=over

=item key (optional, scalar)

If key is specified, add tag(s) to object, otherwise on bucket.

=item tags (mandatory, hashref)

Set specified tags and their respective values.

=item version_id (optional)

Is specified (in conjunction with C<key>) add tag(s) to versioned object.

=back

Returns C<true> on success.

Returns C<false> and sets C<err>/C<errstr> otherwise.

=head2 delete_tags

	# Add tags for a bucket
	$s3->delete_tags ({
		bucket => 'bucket-name',
	});

	# Add tags for an object
	$s3->delete_tags ({
		bucket     => 'bucket-name',
		key        => 'key',
		version_id => $version_id,
	});

Takes configuration parameters

=over

=item key (optional, scalar)

If key is specified, add tag(s) to object, otherwise on bucket.

=item version_id (optional)

Is specified (in conjunction with C<key>) add tag(s) to versioned object.

=back

Returns C<true> on success.

Returns C<false> and sets C<err>/C<errstr> otherwise.

=head1 SEE ALSO

L<Net::Amazon::S3>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
