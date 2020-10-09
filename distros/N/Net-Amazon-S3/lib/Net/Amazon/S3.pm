package Net::Amazon::S3;
# ABSTRACT: Use the Amazon S3 - Simple Storage Service
$Net::Amazon::S3::VERSION = '0.97';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;

use Carp;
use Digest::HMAC_SHA1;
use Safe::Isa ();

use Net::Amazon::S3::Bucket;
use Net::Amazon::S3::Client;
use Net::Amazon::S3::Client::Bucket;
use Net::Amazon::S3::Client::Object;
use Net::Amazon::S3::Error::Handler::Legacy;
use Net::Amazon::S3::HTTPRequest;
use Net::Amazon::S3::Request;
use Net::Amazon::S3::Response;
use Net::Amazon::S3::Operation::Bucket::Acl::Fetch;
use Net::Amazon::S3::Operation::Bucket::Acl::Set;
use Net::Amazon::S3::Operation::Bucket::Create;
use Net::Amazon::S3::Operation::Bucket::Delete;
use Net::Amazon::S3::Operation::Bucket::Location;
use Net::Amazon::S3::Operation::Bucket::Tags::Add;
use Net::Amazon::S3::Operation::Bucket::Tags::Delete;
use Net::Amazon::S3::Operation::Buckets::List;
use Net::Amazon::S3::Operation::Object::Acl::Fetch;
use Net::Amazon::S3::Operation::Object::Acl::Set;
use Net::Amazon::S3::Operation::Object::Add;
use Net::Amazon::S3::Operation::Object::Fetch;
use Net::Amazon::S3::Operation::Object::Delete;
use Net::Amazon::S3::Operation::Object::Restore;
use Net::Amazon::S3::Operation::Object::Tags::Add;
use Net::Amazon::S3::Operation::Object::Tags::Delete;
use Net::Amazon::S3::Operation::Object::Upload::Abort;
use Net::Amazon::S3::Operation::Object::Upload::Complete;
use Net::Amazon::S3::Operation::Object::Upload::Create;
use Net::Amazon::S3::Operation::Object::Upload::Part;
use Net::Amazon::S3::Operation::Object::Upload::Parts;
use Net::Amazon::S3::Operation::Objects::Delete;
use Net::Amazon::S3::Operation::Objects::List;
use Net::Amazon::S3::Signature::V2;
use Net::Amazon::S3::Signature::V4;
use Net::Amazon::S3::Utils;
use Net::Amazon::S3::Vendor;
use Net::Amazon::S3::Vendor::Amazon;
use LWP::UserAgent::Determined;
use URI::Escape qw(uri_escape_utf8);

my $AMAZON_S3_HOST = 's3.amazonaws.com';

has authorization_context => (
	is => 'ro',
	isa => 'Net::Amazon::S3::Authorization',
	required => 0,

	handles => {
		aws_access_key_id     => 'aws_access_key_id',
		aws_secret_access_key => 'aws_secret_access_key',
		aws_session_token     => 'aws_session_token',
	},
);

has vendor => (
	is => 'ro',
	isa => 'Net::Amazon::S3::Vendor',
	required => 1,

	handles => {
		authorization_method => 'authorization_method',
		host                 => 'host',
		secure               => 'use_https',
		use_virtual_host     => 'use_virtual_host',
	},
);

has 'timeout' => ( is => 'ro', isa => 'Num',  required => 0, default => 30 );
has 'retry'   => ( is => 'ro', isa => 'Bool', required => 0, default => 0 );
has 'ua'     => ( is => 'rw', isa => 'LWP::UserAgent', required => 0 );
has 'err'    => ( is => 'rw', isa => 'Maybe[Str]',     required => 0 );
has 'errstr' => ( is => 'rw', isa => 'Maybe[Str]',     required => 0 );
has keep_alive_cache_size => ( is => 'ro', isa => 'Int', required => 0, default => 10 );

has error_handler_class => (
	is => 'ro',
	lazy => 1,
	default => 'Net::Amazon::S3::Error::Handler::Legacy',
);

has error_handler => (
	is => 'ro',
	lazy => 1,
	default => sub { $_[0]->error_handler_class->new (s3 => $_[0]) },
);

has bucket_class => (
	is          => 'ro',
	init_arg    => undef,
	lazy        => 1,
	default     => 'Net::Amazon::S3::Bucket',
);

sub _build_arg_authorization_context {
	my ($args) = @_;

	my $aws_access_key_id     = delete $args->{aws_access_key_id};
	my $aws_secret_access_key = delete $args->{aws_secret_access_key};
	my $use_iam_role          = delete $args->{use_iam_role};
	my $aws_session_token     = delete $args->{aws_session_token};

	if ($args->{authorization_context}) {
		return $args->{authorization_context};
	}

	if ($use_iam_role || $aws_session_token) {
		require Net::Amazon::S3::Authorization::IAM;

		return Net::Amazon::S3::Authorization::IAM->new (
			aws_access_key_id     => $aws_access_key_id,
			aws_secret_access_key => $aws_secret_access_key,
			aws_session_token     => $aws_session_token,
		)
	}

	require Net::Amazon::S3::Authorization::Basic;

	return Net::Amazon::S3::Authorization::Basic->new (
		aws_access_key_id => $aws_access_key_id,
		aws_secret_access_key => $aws_secret_access_key,
	);
}

sub _build_arg_vendor {
	my ($args) = @_;

	my %backward =
		map  { $_ => delete $args->{$_} }
		grep { exists  $args->{$_} }
		qw[ host secure use_virtual_host authorization_method ]
		;

	return $args->{vendor}
		if $args->{vendor};

	$backward{host} = $AMAZON_S3_HOST
		unless exists $backward{host};

	$backward{use_https} = delete $backward{secure}
		if exists $backward{secure};

	my $vendor_class = $backward{host} eq $AMAZON_S3_HOST
		? 'Net::Amazon::S3::Vendor::Amazon'
		: 'Net::Amazon::S3::Vendor'
		;

	return $vendor_class->new (%backward);
}

around BUILDARGS => sub {
	my ($orig, $class) = (shift, shift);
	my $args = $class->$orig (@_);

	# support compat authorization arguments
	$args->{authorization_context} = _build_arg_authorization_context $args;
	$args->{vendor}                = _build_arg_vendor                $args;

	$args;
};


sub BUILD {
	my $self = shift;

	my $ua;
	if ( $self->retry ) {
		$ua = LWP::UserAgent::Determined->new(
			keep_alive            => $self->keep_alive_cache_size,
			requests_redirectable => [qw(GET HEAD DELETE PUT POST)],
		);
		$ua->timing('1,2,4,8,16,32');
	} else {
		$ua = LWP::UserAgent->new(
			keep_alive            => $self->keep_alive_cache_size,
			requests_redirectable => [qw(GET HEAD DELETE PUT POST)],
		);
	}

	$ua->timeout( $self->timeout );
	$ua->env_proxy;

	$self->ua($ua);
}

sub buckets {
	my ($self, %args) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Buckets::List',
		%args,
	);

	return unless $response->is_success;

	my $owner_id          = $response->owner_id;;
	my $owner_displayname = $response->owner_displayname;

	my @buckets;
	foreach my $bucket ($response->buckets) {
		push @buckets, $self->bucket_class->new (
			account       => $self,
			bucket        => $bucket->{name},
			creation_date => $bucket->{creation_date},
		);

	}

	return +{
		owner_id          => $owner_id,
		owner_displayname => $owner_displayname,
		buckets           => \@buckets,
	};
}

sub add_bucket {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_bucket (\@_);

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Create',

		%args,
	);

	return unless $response->is_success;

	return $self->bucket ($args{bucket});
}

sub bucket {
	my ( $self, $bucket ) = @_;

	return $bucket if $bucket->$Safe::Isa::_isa ($self->bucket_class);

	return $self->bucket_class->new(
		{ bucket => $bucket, account => $self } );
}

sub delete_bucket {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_bucket (\@_);

	croak 'must specify bucket'
		unless defined $args{bucket};

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Delete',
		%args,
	);

	return unless $response->is_success;

	return 1;
}

sub list_bucket {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_bucket (\@_);

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Objects::List',
		%args,
	);

	return unless $response->is_success;

	my $return = {
		bucket      => $response->bucket,
		prefix      => $response->prefix,
		marker      => $response->marker,
		next_marker => $response->next_marker,
		max_keys    => $response->max_keys,
		is_truncated => $response->is_truncated,
	};

	my @keys;
	foreach my $node ($response->contents) {
		push @keys, {
			key           => $node->{key},
			last_modified => $node->{last_modified},
			etag          => $node->{etag},
			size          => $node->{size},
			storage_class => $node->{storage_class},
			owner_id      => $node->{owner}{id},
			owner_displayname => $node->{owner}{displayname},
			};
	}
	$return->{keys} = \@keys;

	if ( $args{delimiter} ) {
		$return->{common_prefixes} = [ $response->common_prefixes ];
	}

	return $return;
}

sub list_bucket_all {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_bucket (\@_);

	my $bucket = $args{bucket};
	croak 'must specify bucket' unless $bucket;

	my $response = $self->list_bucket (%args);
	return $response unless $response->{is_truncated};
	my $all = $response;

	while (1) {
		my $next_marker = $response->{next_marker}
			|| $response->{keys}->[-1]->{key};
		$response       = $self->list_bucket (
			%args,
			marker => $next_marker,
		);
		push @{ $all->{keys} }, @{ $response->{keys} };
		last unless $response->{is_truncated};
	}

	delete $all->{is_truncated};
	delete $all->{next_marker};
	return $all;
}

# compat wrapper; deprecated as of 2005-03-23
sub add_key {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_bucket_and_object (\@_);

	my $bucket = $self->bucket (delete $args{bucket});
	return $bucket->add_key (%args);
}

# compat wrapper; deprecated as of 2005-03-23
sub get_key {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_bucket_and_object (\@_);

	my $bucket = $self->bucket (delete $args{bucket});
	return $bucket->get_key (%args);
}

# compat wrapper; deprecated as of 2005-03-23
sub head_key {
	my ( $self, $conf ) = @_;
	my $bucket = $self->bucket (delete $conf->{bucket});
	return $bucket->head_key( $conf->{key} );
}

# compat wrapper; deprecated as of 2005-03-23
sub delete_key {
	my $self = shift;
	my %args = Net::Amazon::S3::Utils->parse_arguments_with_bucket_and_object (\@_);

	my $bucket = $self->bucket (delete $args{bucket});
	return $bucket->delete_key (%args);
}

sub _perform_operation {
	my ($self, $operation, %params) = @_;

	my $error_handler = delete $params{error_handler};
	$error_handler = $self->error_handler unless defined $error_handler;

	my $request_class  = $operation . '::Request';
	my $response_class = $operation . '::Response';
	my $filename = delete $params{filename};

	my $request  = $request_class->new (s3 => $self, %params);
	my $http_response = $self->ua->request ($request->http_request, $filename);
	my $response    = $response_class->new (http_response => $http_response);

	$error_handler->handle_error ($response);

	return $response;
}

sub _urlencode {
	my ( $self, $unencoded ) = @_;
	return uri_escape_utf8( $unencoded, '^A-Za-z0-9_\-\.' );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3 - Use the Amazon S3 - Simple Storage Service

=head1 VERSION

version 0.97

=head1 SYNOPSIS

  use Net::Amazon::S3;
  use Net::Amazon::S3::Authorization::Basic;
  use Net::Amazon::S3::Authorization::IAM;
  my $aws_access_key_id     = 'fill me in';
  my $aws_secret_access_key = 'fill me in too';

  my $s3 = Net::Amazon::S3->new (
    authorization_context => Net::Amazon::S3::Authorization::Basic->new (
      aws_access_key_id     => $aws_access_key_id,
      aws_secret_access_key => $aws_secret_access_key,
    ),
    retry => 1,
  );

  # or use an IAM role.
  my $s3 = Net::Amazon::S3->new (
    authorization_context => Net::Amazon::S3::Authorization::IAM->new (
      aws_access_key_id     => $aws_access_key_id,
      aws_secret_access_key => $aws_secret_access_key,
    ),
    retry => 1,
  );

  # a bucket is a globally-unique directory
  # list all buckets that i own
  my $response = $s3->buckets;
  foreach my $bucket ( @{ $response->{buckets} } ) {
      print "You have a bucket: " . $bucket->bucket . "\n";
  }

  # create a new bucket
  my $bucketname = 'acmes_photo_backups';
  my $bucket = $s3->add_bucket( { bucket => $bucketname } )
      or die $s3->err . ": " . $s3->errstr;

  # or use an existing bucket
  $bucket = $s3->bucket($bucketname);

  # store a file in the bucket
  $bucket->add_key_filename( '1.JPG', 'DSC06256.JPG',
      { content_type => 'image/jpeg', },
  ) or die $s3->err . ": " . $s3->errstr;

  # store a value in the bucket
  $bucket->add_key( 'reminder.txt', 'this is where my photos are backed up' )
      or die $s3->err . ": " . $s3->errstr;

  # list files in the bucket
  $response = $bucket->list_all
      or die $s3->err . ": " . $s3->errstr;
  foreach my $key ( @{ $response->{keys} } ) {
      my $key_name = $key->{key};
      my $key_size = $key->{size};
      print "Bucket contains key '$key_name' of size $key_size\n";
  }

  # fetch file from the bucket
  $response = $bucket->get_key_filename( '1.JPG', 'GET', 'backup.jpg' )
      or die $s3->err . ": " . $s3->errstr;

  # fetch value from the bucket
  $response = $bucket->get_key('reminder.txt')
      or die $s3->err . ": " . $s3->errstr;
  print "reminder.txt:\n";
  print "  content length: " . $response->{content_length} . "\n";
  print "    content type: " . $response->{content_type} . "\n";
  print "            etag: " . $response->{content_type} . "\n";
  print "         content: " . $response->{value} . "\n";

  # delete keys
  $bucket->delete_key('reminder.txt') or die $s3->err . ": " . $s3->errstr;
  $bucket->delete_key('1.JPG')        or die $s3->err . ": " . $s3->errstr;

  # and finally delete the bucket
  $bucket->delete_bucket or die $s3->err . ": " . $s3->errstr;

=head1 DESCRIPTION

This module provides a Perlish interface to Amazon S3. From the
developer blurb: "Amazon S3 is storage for the Internet. It is
designed to make web-scale computing easier for developers. Amazon S3
provides a simple web services interface that can be used to store and
retrieve any amount of data, at any time, from anywhere on the web. It
gives any developer access to the same highly scalable, reliable,
fast, inexpensive data storage infrastructure that Amazon uses to run
its own global network of web sites. The service aims to maximize
benefits of scale and to pass those benefits on to developers".

To find out more about S3, please visit: http://s3.amazonaws.com/

To use this module you will need to sign up to Amazon Web Services and
provide an "Access Key ID" and " Secret Access Key". If you use this
module, you will incurr costs as specified by Amazon. Please check the
costs. If you use this module with your Access Key ID and Secret
Access Key you must be responsible for these costs.

I highly recommend reading all about S3, but in a nutshell data is
stored in values. Values are referenced by keys, and keys are stored
in buckets. Bucket names are global.

Note: This is the legacy interface, please check out
L<Net::Amazon::S3::Client> instead.

Development of this code happens here: https://github.com/rustyconover/net-amazon-s3

=head1 METHODS

=head2 new

Create a new S3 client object. Takes some arguments:

=over

=item authorization_context

Class that provides authorization informations.

See one of available implementations for more

=over

=item L<Net::Amazon::S3::Authorization::Basic>

=item L<Net::Amazon::S3::Authorization::IAM>

=back

=item vendor

Instance of L<Net::Amazon::S3::Vendor> holding vendor specific deviations.

S3 became widely used object storage protocol with many vendors providing
different feature sets and different compatibility level.

One common difference is bucket's HEAD request to determine its region.

To maintain currently known differences along with any differencies that
may rise in feature it's better to hold vendor specification in dedicated
classes. This also allows users to build their own fine-tuned vendor classes.

=over

=item L<Net::Amazon::S3::Vendor::Amazon>

=item L<Net::Amazon::S3::Vendor::Generic>

=back

=item aws_access_key_id

Deprecated.

When used it's used to create authorization context.

Use your Access Key ID as the value of the AWSAccessKeyId parameter
in requests you send to Amazon Web Services (when required). Your
Access Key ID identifies you as the party responsible for the
request.

=item aws_secret_access_key

Deprecated.

When used it's used to create authorization context.

Since your Access Key ID is not encrypted in requests to AWS, it
could be discovered and used by anyone. Services that are not free
require you to provide additional information, a request signature,
to verify that a request containing your unique Access Key ID could
only have come from you.

DO NOT INCLUDE THIS IN SCRIPTS OR APPLICATIONS YOU DISTRIBUTE. YOU'LL BE SORRY

=item aws_session_token

Deprecated.

When used it's used to create authorization context.

If you are using temporary credentials provided by the AWS Security Token
Service, set the token here, and it will be added to the request in order to
authenticate it.

=item use_iam_role

Deprecated.

When used it's used to create authorization context.

If you'd like to use IAM provided temporary credentials, pass this option
with a true value.

=item secure

Deprecated.

Set this to C<0> if you don't want to use SSL-encrypted connections when talking
to S3. Defaults to C<1>.

To use SSL-encrypted connections, LWP::Protocol::https is required.

See L<#vendor> and L<Net::Amazon::S3::Vendor>.

=item keep_alive_cache_size

Set this to C<0> to disable Keep-Alives.  Default is C<10>.

=item timeout

How many seconds should your script wait before bailing on a request to S3? Defaults
to 30.

=item retry

If this library should retry upon errors. This option is recommended.
This uses exponential backoff with retries after 1, 2, 4, 8, 16, 32 seconds,
as recommended by Amazon. Defaults to off.

=item host

Deprecated.

The S3 host endpoint to use. Defaults to 's3.amazonaws.com'. This allows
you to connect to any S3-compatible host.

See L<#vendor> and L<Net::Amazon::S3::Vendor>.

=item use_virtual_host

Deprecated.

Use the virtual host method ('bucketname.s3.amazonaws.com') instead of specifying the
bucket at the first part of the path. This is particularly useful if you want to access
buckets not located in the US-Standard region (such as EU, Asia Pacific or South America).
See L<http://docs.aws.amazon.com/AmazonS3/latest/dev/VirtualHosting.html> for the pros and cons.

See L<#vendor> and L<Net::Amazon::S3::Vendor>.

=item authorization_method

Deprecated.

Authorization implementation package name.

This library provides L<< Net::Amazon::S3::Signature::V2 >> and L<< Net::Amazon::S3::Signature::V4 >>

Default is Signature 4 if host is C<< s3.amazonaws.com >>, Signature 2 otherwise

See L<#vendor> and L<Net::Amazon::S3::Vendor>.

=item error_handler_class

Error handler class name (package name), see L<< Net::Amazon::S3::Error::Handler >>
for more.

Default: L<< Net::Amazon::S3::Error::Handler::Legacy >>

=item error_handler

Instance of error handler class.

=back

=head3 Notes

When using L<Net::Amazon::S3> in child processes using fork (such as in
combination with the excellent L<Parallel::ForkManager>) you should create the
S3 object in each child, use a fresh LWP::UserAgent in each child, or disable
the L<LWP::ConnCache> in the parent:

    $s3->ua( LWP::UserAgent->new( 
        keep_alive => 0, requests_redirectable => [qw'GET HEAD DELETE PUT POST'] );

=head2 buckets

Returns undef on error, else hashref of results

=head2 add_bucket

	# Create new bucket with default location
	my $bucket = $s3->add_bucket ('new-bucket');

	# Create new bucket in another location
	my $bucket = $s3->add_bucket ('new-bucket', location_constraint => 'eu-west-1');
	my $bucket = $s3->add_bucket ('new-bucket', { location_constraint => 'eu-west-1' });
	my $bucket = $s3->add_bucket (bucket => 'new-bucket', location_constraint => 'eu-west-1');
	my $bucket = $s3->add_bucket ({ bucket => 'new-bucket', location_constraint => 'eu-west-1' });

Method creates and returns new bucket.

In case of error it reports it and returns C<undef> (refer L</"ERROR HANDLING">).

Recognized positional arguments (refer L</"CALLING CONVENTION">)

=over

=item bucket

Required, recognized as positional.

The name of the bucket you want to add.

=back

Recognized optional arguments

=over

=item acl

	acl => 'private'
	acl => Net::Amazon::S3::ACL::Canned->PRIVATE
	acl => Net::Amazon::S3::ACL::Set->grant_read (email => 'foo@bar.baz')

I<Available since v0.94>

Set ACL to the newly created bucket. Refer L<Net::Amazon::S3::ACL> for possibilities.

=item acl_short (deprecated)

I<Deprecated since v0.94>

When specified its value is used to populate C<acl> argument (unless it exists).

=item location_constraint

Optional.

Sets the location constraint of the new bucket. If left unspecified, the
default S3 datacenter location will be used.

This library recognizes regions according Amazon S3 documentation

=over

=item →

L<https://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region>

=item →

L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html#API_CreateBucket_RequestSyntax>

=back

=back

Provides operation L<CreateBucket|https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateBucket.html>.

=head2 bucket BUCKET

Takes a scalar argument, the name of the bucket you're creating

Returns an (unverified) bucket object from an account. Does no network access.

=head2 delete_bucket

	$s3->delete_bucket ($bucket);
	$s3->delete_bucket (bucket => $bucket);

Deletes bucket from account.

Returns C<true> if the bucket is successfully deleted.

Returns C<false> and reports an error otherwise (refer L</"ERROR HANDLING">)

Positional arguments (refer L</"CALLING CONVENTION">)

=over

=item bucket

Required.

The name of the bucket or L<Net::Amazon::S3::Bucket> instance you want to delete.

=back

Provides operation L<"DeleteBucket"|https://docs.aws.amazon.com/AmazonS3/latest/API/API_DeleteBucket.html>

=head2 list_bucket

List all keys in this bucket.

Takes a hashref of arguments:

MANDATORY

=over

=item bucket

The name of the bucket you want to list keys on

=back

OPTIONAL

=over

=item prefix

Restricts the response to only contain results that begin with the
specified prefix. If you omit this optional argument, the value of
prefix for your query will be the empty string. In other words, the
results will be not be restricted by prefix.

=item delimiter

If this optional, Unicode string parameter is included with your
request, then keys that contain the same string between the prefix
and the first occurrence of the delimiter will be rolled up into a
single result element in the CommonPrefixes collection. These
rolled-up keys are not returned elsewhere in the response.  For
example, with prefix="USA/" and delimiter="/", the matching keys
"USA/Oregon/Salem" and "USA/Oregon/Portland" would be summarized
in the response as a single "USA/Oregon" element in the CommonPrefixes
collection. If an otherwise matching key does not contain the
delimiter after the prefix, it appears in the Contents collection.

Each element in the CommonPrefixes collection counts as one against
the MaxKeys limit. The rolled-up keys represented by each CommonPrefixes
element do not.  If the Delimiter parameter is not present in your
request, keys in the result set will not be rolled-up and neither
the CommonPrefixes collection nor the NextMarker element will be
present in the response.

=item max-keys

This optional argument limits the number of results returned in
response to your query. Amazon S3 will return no more than this
number of results, but possibly less. Even if max-keys is not
specified, Amazon S3 will limit the number of results in the response.
Check the IsTruncated flag to see if your results are incomplete.
If so, use the Marker parameter to request the next page of results.
For the purpose of counting max-keys, a 'result' is either a key
in the 'Contents' collection, or a delimited prefix in the
'CommonPrefixes' collection. So for delimiter requests, max-keys
limits the total number of list results, not just the number of
keys.

=item marker

This optional parameter enables pagination of large result sets.
C<marker> specifies where in the result set to resume listing. It
restricts the response to only contain results that occur alphabetically
after the value of marker. To retrieve the next page of results,
use the last key from the current page of results as the marker in
your next request.

See also C<next_marker>, below.

If C<marker> is omitted,the first page of results is returned.

=back

Returns undef on error and a hashref of data on success:

The hashref looks like this:

  {
        bucket          => $bucket_name,
        prefix          => $bucket_prefix,
        common_prefixes => [$prefix1,$prefix2,...]
        marker          => $bucket_marker,
        next_marker     => $bucket_next_available_marker,
        max_keys        => $bucket_max_keys,
        is_truncated    => $bucket_is_truncated_boolean
        keys            => [$key1,$key2,...]
   }

Explanation of bits of that:

=over

=item common_prefixes

If list_bucket was requested with a delimiter, common_prefixes will
contain a list of prefixes matching that delimiter.  Drill down into
these prefixes by making another request with the prefix parameter.

=item is_truncated

B flag that indicates whether or not all results of your query were
returned in this response. If your results were truncated, you can
make a follow-up paginated request using the Marker parameter to
retrieve the rest of the results.

=item next_marker

A convenience element, useful when paginating with delimiters. The
value of C<next_marker>, if present, is the largest (alphabetically)
of all key names and all CommonPrefixes prefixes in the response.
If the C<is_truncated> flag is set, request the next page of results
by setting C<marker> to the value of C<next_marker>. This element
is only present in the response if the C<delimiter> parameter was
sent with the request.

=back

Each key is a hashref that looks like this:

     {
        key           => $key,
        last_modified => $last_mod_date,
        etag          => $etag, # An MD5 sum of the stored content.
        size          => $size, # Bytes
        storage_class => $storage_class # Doc?
        owner_id      => $owner_id,
        owner_displayname => $owner_name
    }

=head2 list_bucket_all

List all keys in this bucket without having to worry about
'marker'. This is a convenience method, but may make multiple requests
to S3 under the hood.

Takes the same arguments as list_bucket.

=head2 _perform_operation

    my $response = $s3->_perform_operation ('Operation' => (
        # ... operation request parameters
    ));

Internal operation implementation method, takes request construction parameters,
performs necessary HTTP requests(s) and returns Response instance.

Method takes same named parameters as realted Request class.

Method provides available contextual parameters by default (eg s3, bucket)

Method invokes contextual error handler.

=head1 CALLING CONVENTION

I<Available since v0.97> - calling convention extentend

In order to make method calls somehow consistent, backward compatible,
and extendable, API's methods support multiple ways how to provide their arguments

=over

=item plain named arguments (preferred)

	method (named => 'argument', another => 'argument');

=item trailing configuration hash

	method ({ named => 'argument', another => 'argument' });
	method (positional, { named => 'argument', another => 'argument' } );

Last argument of every method can be configuration hash, treated as additional
named arguments. Can be combined with named arguments.

=item positional arguments with optional named arguments

	method (positional, named => 'argument', another => 'argument');
	method (positional, { named => 'argument', another => 'argument' } );

For methods supporting mandatory positional arguments additional named
arguments and/or configuration hash is supported.

Named arguments or configuration hash can specify value of positional
arguments as well removing it from list of required positional arguments
for given call (see example)

	$s3->bucket->add_key ('key', 'value', acl => $acl);
	$s3->bucket->add_key ('value', key => 'key', acl => $acl);
	$s3->bucket->add_key (key => 'key', value => 'value', acl => $acl);

=back

=head1 ERROR HANDLING

L<Net::Amazon::S3> supports pluggable error handling via
L<Net::Amazon::S3::Error::Handler>.

When response ends up with an error, every method reports it, and in case it
receives control back (no exception), it returns C<undef>.

Default error handling for L<Net::Amazon::S3> is L<Net::Amazon::S3::Error::Handler::Legacy>
which (mostly) sets C<err> and C<errstr>.

=head1 LICENSE

This module contains code modified from Amazon that contains the
following notice:

  #  This software code is made available "AS IS" without warranties of any
  #  kind.  You may copy, display, modify and redistribute the software
  #  code either by itself or as incorporated into your code; provided that
  #  you do not remove any proprietary notices.  Your use of this software
  #  code is at your own risk and you waive any claim against Amazon
  #  Digital Services, Inc. or its affiliates with respect to your use of
  #  this software code. (c) 2006 Amazon Digital Services, Inc. or its
  #  affiliates.

=head1 TESTING

Testing S3 is a tricky thing. Amazon wants to charge you a bit of
money each time you use their service. And yes, testing counts as using.
Because of this, the application's test suite skips anything approaching
a real test unless you set these three environment variables:

=over

=item AMAZON_S3_EXPENSIVE_TESTS

Doesn't matter what you set it to. Just has to be set

=item AWS_ACCESS_KEY_ID

Your AWS access key

=item AWS_ACCESS_KEY_SECRET

Your AWS sekkr1t passkey. Be forewarned that setting this environment variable
on a shared system might leak that information to another user. Be careful.

=back

=head1 AUTHOR

Leon Brocard <acme@astray.com> and unknown Amazon Digital Services programmers.

Brad Fitzpatrick <brad@danga.com> - return values, Bucket object

Pedro Figueiredo <me@pedrofigueiredo.org> - since 0.54

Branislav Zahradník <barney@cpan.org> - since v0.81

=head1 SEE ALSO

L<Net::Amazon::S3::Bucket>

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
