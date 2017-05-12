use strict;
use warnings;
use autodie;
package Net::Google::Storage;
{
  $Net::Google::Storage::VERSION = '0.1.2';
}

# ABSTRACT: Access the Google Storage JSON API (currently experimental).
# https://developers.google.com/storage/docs/json_api/

use Moose;
use LWP::UserAgent;
use JSON;
use HTTP::Status qw(:constants);

use Net::Google::Storage::Bucket;
use Net::Google::Storage::Object;

with 'Net::Google::Storage::Agent';


has projectId => (
	is => 'rw',
	isa => 'Int',
);

my $api_base = 'https://www.googleapis.com/storage/v1beta1/b';
my $upload_api_base = 'https://www.googleapis.com/upload/storage/v1beta1/b';


sub list_buckets
{
	my $self = shift;
	
	my $projectId = $self->projectId;
	
	my $res = $self->_get("$api_base?projectId=$projectId");
	
	die 'Failed to list buckets' unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	my @buckets = map {Net::Google::Storage::Bucket->new($_)} @{$response->{items}};
	return \@buckets;
}


sub get_bucket
{
	my $self = shift;
	
	my $bucket_name = shift;
	
	my $res = $self->_get($self->_form_url("$api_base/%s", $bucket_name));
	return undef if $res->code == HTTP_NOT_FOUND;
	die "Failed to get bucket: $bucket_name" unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Bucket->new($response);
}


sub insert_bucket
{
	my $self = shift;
	
	my $bucket_args = shift;
	$bucket_args->{projectId} ||= $self->projectId;
	my $res = $self->_json_post($api_base, $bucket_args);
	die "Failed to create bucket: $bucket_args->{id}" unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Bucket->new($response);
}


sub delete_bucket
{
	my $self = shift;
	
	my $bucket_name = shift;
	
	my $res = $self->_delete($self->_form_url("$api_base/%s", $bucket_name));
	die "Failed to delete bucket: $bucket_name" unless $res->is_success;
	
	return;
}


sub list_objects
{
	my $self = shift;
	
	my $bucket = shift;
	
	my $res = $self->_get($self->_form_url("$api_base/%s/o", $bucket));
	
	die 'Failed to list objects' unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	my @objects = map {Net::Google::Storage::Object->new($_)} @{$response->{items}};
	return \@objects;
}


sub get_object
{
	my $self = shift;
	
	my %args = @_;
	
	my $res = $self->_get($self->_form_url("$api_base/%s/o/%s?alt=json", $args{bucket}, $args{object}));
	return undef if $res->code == HTTP_NOT_FOUND;
	die "Failed to get object: $args{object} in bucket: $args{bucket}" unless $res->is_success;
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Object->new($response);
}


sub download_object
{
	my $self = shift;
	
	my %args = @_;
	
	my $res = $self->_get($self->_form_url("$api_base/%s/o/%s", $args{bucket}, $args{object}), ':content_file' => $args{filename});
	return undef if $res->code == HTTP_NOT_FOUND;
	die "Failed to get object: $args{object} in bucket: $args{bucket}" unless $res->is_success;
}


sub insert_object
{
	my $self = shift;
	
	my %args = @_;
	
	my $url = $self->_form_url("$upload_api_base/%s/o?uploadType=resumable", $args{bucket});
	my $filename = $args{filename} || die 'A filename is required';
	
	die "Unable to find $filename" unless -e $filename;
	my $filesize = -s _;
	
	my $object_hash = $args{object};
	unless($object_hash->{media}->{contentType})
	{
		require LWP::MediaTypes;
		$object_hash->{media}->{contentType} = LWP::MediaTypes::guess_media_type($filename);
	}
	
	my $content_type = $object_hash->{media}->{contentType};
	my $res = $self->_json_post($url, 'X-Upload-Content-Type' => $content_type, 'X-Upload-Content-Length' => $filesize, $object_hash);
	my $resumable_url = $res->header('Location');
	
	my %headers = (
		'Content-Length' => $filesize,
		'Content-Type' => $content_type,
	);
	
	local $/;
	open(my $fh, '<', $filename);
	my $file_contents = <$fh>;
	
	$res = $self->_put($resumable_url, %headers, Content => $file_contents);
	
	#resuming code
	my $retry_count = 0;
	my $code = $res->code;
	while($code >=500 && $code <600 && $retry_count++ < 8)
	{
		sleep 2**$retry_count;
		$res = $self->_put($resumable_url, 'Content-Length' => 0, 'Content-Range' => "bytes */$filesize");
		last if $res->is_success;
		next unless $res->code == 308;
		
		my $range = $res->header('Range');
		next unless $range;
		
		if($range =~ /bytes=0-(\d+)/)
		{
			my $offset = $1+1;
			seek($fh, $offset, 0);
			$file_contents = <$fh>;
			
			%headers = (
				'Content-Length' => $filesize - $offset,
				'Content-Range' => sprintf('bytes %d-%d/%d', $offset, $filesize-1, $filesize),
			);
			$res = $self->_put($resumable_url, %headers, Content => $file_contents);
			$code = $res->code;
		}
		else
		{
			next;
		}
	}
	
	my $response = decode_json($res->decoded_content);
	
	return Net::Google::Storage::Object->new($response);
}


sub delete_object
{
	my $self = shift;
	
	my %args = @_;
	
	my $res = $self->_delete($self->_form_url("$api_base/%s/o/%s", $args{bucket}, $args{object}));
	die "Failed to delete object: $args{object} in bucket: $args{bucket}" unless $res->is_success;
	
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Net::Google::Storage - Access the Google Storage JSON API (currently experimental).

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

  my $gs = Net::Google::Storage->new(
    projectId => $projectId,
    %agent_args
  );

See L<Net::Google::Storage::Agent> for a decription of C<%agent_args>.

  my $buckets = $gs->list_buckets();

  my $bucket = $gs->get_bucket($bucket_name);

  my $new_bucket = $gs->insert_bucket({id => $new_bucket_name});

  $gs->delete_bucket($bucket_name);

  my $objects = $gs->list_objects($bucket_name);

  my $object = $gs->get_object(bucket => $bucket_name, object => $object_name);

  $gs->download_object(bucket => $bucket_name, object => $object_name, filename => $filename);

  my $object = $gs->insert_object(bucket => $bucket_name, object => {name => $object_name}, filename => $filename);

  $gs->delete_object(bucket => $bucket_name, object => $object_name);

=head1 DESCRIPTION

Net::Google::Storage is a library for interacting with the JSON version of
the Google Storage API, which is currently (as at 2012-09-17) marked as
experimental.

This module does not (yet) cover the entire surface of the API, but it is a
decent attempt at providing the most important functionality.

See L<https://developers.google.com/storage/docs/json_api/> for documentation
of the API itself.

=head1 ATTRIBUTES

=head2 projectId

Google's identifier of the project you are accessing. Available from the
L<API Console|https://code.google.com/apis/console/#:storage>.

=head1 METHODS

=head2 new

Constructs a shiny new B<Net::Google::Storage> object. Arguments include
C<projectId> and the attributes of L<Net::Google::Storage::Agent>

=head2 list_buckets

Returns an arrayref of L<Net::Google::Storage::Bucket> objects for the
current projectId.

=head2 get_bucket

Takes a bucket name as the only argument, returns the matching
L<Net::Google::Storage::Bucket> object or undef if nothing matches.

=head2 insert_bucket

Takes some bucket metadata as the only argument (could be as simple as
C<< {id => $bucket_name} >>), creates a new bucket and returns the matching
L<Net::Google::Storage::Bucket> object.

=head2 delete_bucket

Takes a bucket name as the only argument, deletes the bucket.

=head2 list_objects

Takes a bucket name as the only argument, returns an arrayref of
L<Net::Google::Storage::Object> objects.

=head2 get_object

Takes a hash (not hashref) of arguments with keys: I<bucket> and I<object>
and returns the matching L<Net::Google::Storage::Object> object (or undef if
no match was found).

=head2 download_object

Takes a hash (not hashref) of arguments with keys: I<bucket>, I<object>, and
I<filename> and downloads the matching object as the desired filename.

Returns undef if the object doesn't exist, true for success.

=head2 insert_object

Takes a hash of arguments with keys: I<bucket>, I<filename> and I<object>
where I<object> contains the necessary metadata to upload the file, which is,
at minimum, the I<name> field.

=head2 delete_object

Takes a hash of arguments with keys: I<bucket> and I<object> and deletes the
matching object.

=head1 AUTHOR

Glenn Fowler <cebjyre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Glenn Fowler.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

