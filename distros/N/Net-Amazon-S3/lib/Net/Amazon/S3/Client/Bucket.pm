package Net::Amazon::S3::Client::Bucket;
$Net::Amazon::S3::Client::Bucket::VERSION = '0.991';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
use Data::Stream::Bulk::Callback;
use MooseX::Types::DateTime::MoreCoercions 0.07 qw( DateTime );

# ABSTRACT: An easy-to-use Amazon S3 client bucket

has 'client' =>
	( is => 'ro', isa => 'Net::Amazon::S3::Client', required => 1 );
has 'name' => ( is => 'ro', isa => 'Str', required => 1 );
has 'creation_date' =>
	( is => 'ro', isa => DateTime, coerce => 1, required => 0 );
has 'owner_id'           => ( is => 'ro', isa => 'Str', required => 0 );
has 'owner_display_name' => ( is => 'ro', isa => 'Str',     required => 0 );
has 'region' => (
	is => 'ro',
	lazy => 1,
	predicate => 'has_region',
	default => sub { $_[0]->location_constraint },
);


__PACKAGE__->meta->make_immutable;

sub _create {
	my ($self, %conf) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Create',

		(acl                => $conf{acl})       x!! defined $conf{acl},
		(acl_short          => $conf{acl_short}) x!! defined $conf{acl_short},
		(location_constraint => $conf{location_constraint}) x!! defined $conf{location_constraint},
	);

	return unless $response->is_success;

	return $response->http_response;
}

sub delete {
	my $self = shift;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Delete',
	);

	return unless $response->is_success;
	return $response->http_response;
}

sub acl {
	my $self = shift;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Acl::Fetch',
	);

	return if $response->is_error;
	return $response->http_response->content;
}

sub set_acl {
	my ($self, %params) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Acl::Set',
		%params,
	);

	return $response->is_success;
}

sub add_tags {
	my ($self, %params) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Tags::Add',

		tags   => $params{tags},
	);

	return $response->is_success;
}

sub delete_tags {
	my ($self, $conf) = @_;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Tags::Delete',
	);

	return $response->is_success;
}

sub location_constraint {
	my $self = shift;

	my $response = $self->_perform_operation (
		'Net::Amazon::S3::Operation::Bucket::Location',
	);

	return unless $response->is_success;
	return $response->location;
}

sub object_class { 'Net::Amazon::S3::Client::Object' }

sub list {
	my ( $self, $conf ) = @_;
	$conf ||= {};
	my $prefix = $conf->{prefix};
	my $delimiter = $conf->{delimiter};

	my $marker = undef;
	my $end    = 0;

	return Data::Stream::Bulk::Callback->new(
		callback => sub {

			return undef if $end;

			my $response = $self->_perform_operation (
				'Net::Amazon::S3::Operation::Objects::List',

				marker    => $marker,
				prefix    => $prefix,
				delimiter => $delimiter,
			);

			return unless $response->is_success;

			my @objects;
			foreach my $node ($response->contents) {
				push @objects, $self->object_class->new (
					client => $self->client,
					bucket => $self,
					key    => $node->{key},
					etag   => $node->{etag},
					size   => $node->{size},
					last_modified_raw => $node->{last_modified},
				);
			}

			return undef unless @objects;

			$end = 1 unless $response->is_truncated;

			$marker = $response->next_marker
				|| $objects[-1]->key;

			return \@objects;
		}
	);
}

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

		$last_result = $response;

		last unless $response->is_success;
	}
	return $last_result->http_response;
}

sub object {
	my ( $self, %conf ) = @_;
	return $self->object_class->new(
		client => $self->client,
		bucket => $self,
		%conf,
	);
}

sub _perform_operation {
	my ($self, $operation, %params) = @_;

	$self->client->_perform_operation ($operation => (
		bucket => $self->name,
		%params,
	));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Client::Bucket - An easy-to-use Amazon S3 client bucket

=head1 VERSION

version 0.991

=head1 SYNOPSIS

  # return the bucket name
  print $bucket->name . "\n";

  # return the bucket location constraint
  print "Bucket is in the " . $bucket->location_constraint . "\n";

  # return the ACL XML
  my $acl = $bucket->acl;

  # list objects in the bucket
  # this returns a L<Data::Stream::Bulk> object which returns a
  # stream of L<Net::Amazon::S3::Client::Object> objects, as it may
  # have to issue multiple API requests
  my $stream = $bucket->list;
  until ( $stream->is_done ) {
    foreach my $object ( $stream->items ) {
      ...
    }
  }

  # or list by a prefix
  my $prefix_stream = $bucket->list( { prefix => 'logs/' } );

  # returns a L<Net::Amazon::S3::Client::Object>, which can then
  # be used to get or put
  my $object = $bucket->object( key => 'this is the key' );

  # delete the bucket (it must be empty)
  $bucket->delete;

=head1 DESCRIPTION

This module represents buckets.

=for test_synopsis no strict 'vars'

=head1 METHODS

=head2 acl

  # return the ACL XML
  my $acl = $bucket->acl;

=head2 add_tags

	$bucket->add_tags (
		tags => { tag1 => 'val1', ... },
	)

=head2 delete_tags

	$bucket->delete_tags;

=head2 delete

  # delete the bucket (it must be empty)
  $bucket->delete;

=head2 list

  # list objects in the bucket
  # this returns a L<Data::Stream::Bulk> object which returns a
  # stream of L<Net::Amazon::S3::Client::Object> objects, as it may
  # have to issue multiple API requests
  my $stream = $bucket->list;
  until ( $stream->is_done ) {
    foreach my $object ( $stream->items ) {
      ...
    }
  }

  # or list by a prefix
  my $prefix_stream = $bucket->list( { prefix => 'logs/' } );

  # you can emulate folders by using prefix with delimiter
  # which shows only entries starting with the prefix but
  # not containing any more delimiter (thus no subfolders).
  my $folder_stream = $bucket->list( { prefix => 'logs/', delimiter => '/' } );

=head2 location_constraint

  # return the bucket location constraint
  print "Bucket is in the " . $bucket->location_constraint . "\n";

=head2 name

  # return the bucket name
  print $bucket->name . "\n";

=head2 object

  # returns a L<Net::Amazon::S3::Client::Object>, which can then
  # be used to get or put
  my $object = $bucket->object( key => 'this is the key' );

=head2 delete_multi_object

  # delete multiple objects using a multi object delete operation
  # Accepts a list of L<Net::Amazon::S3::Client::Object or String> objects.
  $bucket->delete_multi_object($object1, $object2)

=head2 object_class

  # returns string "Net::Amazon::S3::Client::Object"
  # allowing subclasses to add behavior.
  my $object_class = $bucket->object_class;

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
