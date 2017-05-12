package Net::Amazon::Glacier;

use 5.10.0;
use strict;
use warnings;

use Net::Amazon::Signature::V4;
use Net::Amazon::TreeHash;

use HTTP::Request;
use LWP::UserAgent;
use JSON 2.61;
use POSIX;
use Digest::SHA;
use File::Slurp 9999.19;
use Carp;

=head1 NAME

Net::Amazon::Glacier - An implementation of the full Amazon Glacier RESTful 2012-06-01 API.

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

Amazon Glacier is Amazon's long-term storage service and can be used to store
cold archives with a novel pricing scheme.
This module implements the full Amazon Glacier RESTful API, version 2012-06-01
(current at writing). It can be used to manage Glacier vaults, upload archives
as single part or multipart up to 40.000Gb in a single element and download them
in ranges or single parts.

Perhaps a little code snippet:

	use Net::Amazon::Glacier;

	my $glacier = Net::Amazon::Glacier->new(
		'eu-west-1',
		'AKIMYACCOUNTID',
		'MYSECRET',
	);

	my $vault = 'a_vault';

	my @vaults = $glacier->list_vaults();

	if ( $glacier->create_vault( $vault ) ) {

		if ( my $archive_id = $glacier->upload_archive( './archive.7z' ) ) {

			my $job_id = $glacier->inititate_job( $vault, $archive_id );

			# Jobs generally take about 4 hours to complete
			my $job_description = $glacier->describe_job( $vault, $job_id );

			# For a better way to wait for completion, see
			# http://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html
			while ( $job_description->{'StatusCode'} ne 'Succeeded' ) {
				sleep 15 * 60 * 60;
				$job_description = $glacier->describe_job( $vault, $job_id );
			}

			my $archive_bytes = $glacier->get_job_output( $vault, $job_id );

			# Jobs live as completed jobs for "a period", according to
			# http://docs.aws.amazon.com/amazonglacier/latest/dev/api-jobs-get.html
			my @jobs = $glacier->list_jobs( $vault );

			# As of 2013-02-09 jobs are blindly created even if a job for the same archive_id and Range exists.
			# Keep $archive_ids, reuse the expensive job resource, and remember 4 hours.
			foreach my $job ( @jobs ) {
				next unless $job->{ArchiveId} eq $archive_id;
				my $archive_bytes = $glacier->get_job_output( $vault, $job_id );
			}

		}

	}

The functions are intended to closely reflect Amazon's Glacier API. Please see
Amazon's API reference for documentation of the functions:
L<http://docs.amazonwebservices.com/amazonglacier/latest/dev/amazon-glacier-api.html>.

=head1 CONSTRUCTOR

=head2 new( $region, $access_key_id, $secret )

=cut

sub new {
	my ( $class, $region, $access_key_id, $secret ) = @_;

	croak "no region specified" unless $region;
	croak "no access key specified" unless $access_key_id;
	croak "no secret specified" unless $secret;

	my $self = {
		region => $region,
		# be well behaved and tell who we are
		ua     => LWP::UserAgent->new( agent=> __PACKAGE__ . '/' . $VERSION ),
		sig    => Net::Amazon::Signature::V4->new( $access_key_id, $secret, $region, 'glacier' ),
	};
	return bless $self, $class;
}

=head1 VAULT OPERATORS

=head2 create_vault( $vault_name )

Creates a vault with the specified name. Returns true on success, croaks on failure.
L<Create Vault (PUT vault)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-put.html>
=cut

sub create_vault {
	my ( $self, $vault_name ) = @_;

	croak "no vault name given" unless $vault_name;

	my $res = $self->_send_receive( PUT => "/-/vaults/$vault_name" );

	# updated error severity
	croak 'describe_vault failed with error ' . $res->status_line
		unless $res->is_success;

	return 1;

}

=head2 delete_vault( $vault_name )

Deletes the specified vault. Returns true on success, croaks on failure.

L<Delete Vault (DELETE vault)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-delete.html>
=cut

sub delete_vault {
	my ( $self, $vault_name ) = @_;

	croak "no vault name given" unless $vault_name;

	my $res = $self->_send_receive( DELETE => "/-/vaults/$vault_name" );
	# updated error severity
	croak 'describe_vault failed with error ' . $res->status_line
		unless $res->is_success;

	return 1;
}

=head2 describe_vault( $vault_name )

Fetches information about the specified vault.

Returns a hash reference with
the keys described by L<http://docs.amazonwebservices.com/amazonglacier/latest/dev/api-vault-get.html>.

Croaks on failure.

L<Describe Vault (GET vault)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-get.html>

=cut

sub describe_vault {
	my ( $self, $vault_name ) = @_;

	croak "no vault name given" unless $vault_name;

	my $res = $self->_send_receive( GET => "/-/vaults/$vault_name" );
	# updated error severity
	croak 'describe_vault failed with error ' . $res->status_line unless $res->is_success;

	return $self->_decode_and_handle_response( $res );
}

=head2 list_vaults

Lists the vaults. Returns an array with all vaults.
L<Amazon Glacier List Vaults (GET vaults)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-vaults-get.html>.

A call to list_vaults can result in many calls to the Amazon API at a rate
of 1 per 1,000 vaults in existence.
Calls to List Vaults in the API are L<free|http://aws.amazon.com/glacier/pricing/#storagePricing>.

Croaks on failure.

=cut

sub list_vaults {
	my ( $self ) = @_;
	my @vaults;

	my $marker;
	do {
		#1000 is the default limit, send a marker if needed
		my $res = $self->_send_receive( GET => "/-/vaults?limit=1000" . ($marker?'&'.$marker:'') );
		# updated error severity
		croak 'list_vaults failed with error ' . $res->status_line unless $res->is_success;
		my $decoded = $self->_decode_and_handle_response( $res );

		push @vaults, @{$decoded->{VaultList}};
		$marker = $decoded->{Marker};
	} while ( $marker );

	return ( \@vaults );
}

=head2 set_vault_notifications( $vault_name, $sns_topic, $events )

Sets vault notifications for a given vault.

An SNS Topic to send notifications to must be provided. The SNS Topic must
grant permission to the vault to be allowed to publish notifications to the topic.

An array ref to a list of events must be provided. Valid events are
ArchiveRetrievalCompleted and InventoryRetrievalCompleted

Return true on success, croaks on failure.

L<Set Vault Notification Configuration (PUT notification-configuration)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-put.html>.

=cut

sub set_vault_notifications {
	my ( $self, $vault_name, $sns_topic, $events ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no sns topic given" unless $sns_topic;
	croak "events should be an array ref" unless ref $events eq 'ARRAY';

	my $content_raw;

	$content_raw->{SNSTopic} = $sns_topic
		if defined($sns_topic);

	$content_raw->{Events} = $events
		if defined($events);

	my $res = $self->_send_receive(
		PUT => "/-/vaults/$vault_name/notification-configuration",
		[
		],
		encode_json($content_raw),
	);
	# updated error severity
	croak 'get_vault_notifications failed with error ' . $res->status_line
		unless $res->is_success;

	return 1;
}

=head2 get_vault_notifications( $vault_name )

Gets vault notifications status for a given vault.

Returns a hash with an 'SNSTopic' and and array of 'Events' on success, croaks
on failure.

L<Get Vault Notifications (GET notification-configuration)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-get.html>.

=cut

sub get_vault_notifications {
	my ( $self, $vault_name, $sns_topic, $events ) = @_;

	croak "no vault name given" unless $vault_name;

	my $res = $self->_send_receive(
		PUT => "/-/vaults/$vault_name/notification-configuration",
	);
	# updated error severity
	croak 'get_vault_notifications failed with error ' . $res->status_line
		unless $res->is_success;

	return $self->_decode_and_handle_response( $res );
}

=head2 delete_vault_notifications( $vault_name )

Deletes vault notifications for a given vault.

Return true on success, croaks on failure.

L<Delete Vault Notifications (DELETE notification-configuration)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-vault-notifications-delete.html>.

=cut

sub delete_vault_notifications {
	my ( $self, $vault_name, $sns_topic, $events ) = @_;

	croak "no vault name given" unless $vault_name;

	my $res = $self->_send_receive(
		DELETE => "/-/vaults/$vault_name/notification-configuration",
	);
	# updated error severity
	croak 'delete_vault_notifications failed with error ' . $res->status_line
		unless $res->is_success;

	return 1;
}

=head1 ARCHIVE OPERATIONS

=head2 upload_archive( $vault_name, $archive_path, [ $description ] )

Uploads an archive to the specified vault. $archive_path is the local path to
any file smaller than 4GB. For larger files, see MULTIPART UPLOAD OPERATIONS.

An archive description of up to 1024 printable ASCII characters can be supplied.

Returns the Amazon-generated archive ID on success, or false on failure.

L<Upload Archive (POST archive)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-post.html>

=cut

sub upload_archive {
	my ( $self, $vault_name, $archive_path, $description ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no archive path given" unless $archive_path;
	croak 'archive path is not a file' unless -f $archive_path;

	$description //= '';
	my $content = File::Slurp::read_file( $archive_path, err_mode => 'croak', binmode => ':raw', scalar_ref => 1 );

	return $self->_do_upload($vault_name, $content, $description);
}

=head2 upload_archive_from_ref( $vault_name, $ref, [ $description ] )

DEPRECATED at birth. Will be dropped in next version. A more robust
upload_archive will support file paths, refs, code refs, filehandles and more.

In the meanwhile...

Like upload_archive, but takes a reference to your data instead of the path to
a file. For data greater than 4GB, see multi-part upload. An archive
description of up to 1024 printable ASCII characters can be supplied. Returns
the Amazon-generated archive ID on success, or false on failure.

=cut

sub upload_archive_from_ref {
	my ( $self, $vault_name, $ref, $description ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "data must be a reference" unless ref $ref;

	return $self->_do_upload($vault_name, $ref, $description);
}

sub _do_upload {
	my ( $self, $vault_name, $content_ref, $description ) = @_;

	_enforce_description_limits( \$description );

	my $th = Net::Amazon::TreeHash->new();
	$th->eat_data ( $content_ref );
	$th->calc_tree;

	my $res = $self->_send_receive(
		POST => "/-/vaults/$vault_name/archives",
		[
			'x-amz-archive-description' => $description,
			'x-amz-sha256-tree-hash' => $th->get_final_hash(),
			'x-amz-content-sha256' => Digest::SHA::sha256_hex( $$content_ref ),
		],
		$$content_ref
	);
	croak 'upload_archive failed with error ' . $res->status_line unless $res->is_success;

	my $rec_archive_id;
	unless ( $res->header('location') =~ m{^/[^/]+/vaults/[^/]+/archives/(.*)$} ) {
		# update severity of error. This method must return an archive id
		croak 'request succeeded, but reported archive location does not match regex: ' . $res->header('location');
	} else {
		$rec_archive_id = $1;
	}

	return $rec_archive_id;
}

=head2 delete_archive( $vault_name, $archive_id )

Issues a request to delete a file from Glacier. $archive_id is the ID you
received either when you uploaded the file originally or from an inventory.
L<Delete Archive (DELETE archive)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-archive-delete.html>

=cut

sub delete_archive {
	my ( $self, $vault_name, $archive_id ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no archive ID given" unless $archive_id;

	my $res = $self->_send_receive( DELETE => "/-/vaults/$vault_name/archives/$archive_id" );
	# updated error severity
	croak 'delete_archive failed with error ' . $res->status_line unless $res->is_success;

	return $res->is_success;
}

=head1 MULTIPART UPLOAD OPERATIONS

Amazon requires this method for files larger than 4GB, and recommends it for
files larger than 100MB.

L<Uploading Large Archives in Parts (Multipart Upload)|http://docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html>

=head2 SYNOPSIS

	use Net::Amazon::Glacier;

	my $glacier = Net::Amazon::Glacier->new(
		'eu-west-1',
		'AKIMYACCOUNTID',
		'MYSECRET',
	);

	my $part_size = $glacier->calculate_multipart_upload_partsize( -s $filename );

	my $upload_id = $glacier->multipart_upload_init( $vault, $part_size, $description );

	open ( A_FILE, '<', 'a_file.bin' );

	my $part_index = 0;
	my $read_bytes;
	my $parts_hash = []; # to store partial tree hash for complete method

	# Upload parts of A_FILE
	do {
		$read_bytes = read ( A_FILE, $part, $part_size );
		$parts_hash->[$part_index] = $glacier->multipart_upload_upload_part( $vault, $upload_id, $part_size, $part_index, \$part );
	} while ( ( $read_bytes == $part_size) && $parts_hash->[$part_index++] =~ /^[0-9a-f]{64}$/ );
	close ( A_FILE );

	my $archive_size = $part_size * ( $part_index ) + $read_bytes;

	# Capture archive id or error code
	my $archive_id = $glacier->multipart_upload_complete( $vault, $upload_id, $parts_hash, $archive_size  );

	# Check if we have a valid $archive_id
	unless ( $archive_id =~ /^[a-zA-Z0-9_\-]{10,}$/ ) {
		# abort partial failed upload
		# could also store upload_id and continue later
		$glacier->multipart_upload_abort( $vault, $upload_id );
	}

	# Other useful methods
	# Get an array ref with incomplete multipart uploads
	my $upload_list = $glacier->multipart_upload_list_uploads( $vault );

	# Get an array ref with uploaded parts for a multipart upload
	my $upload_parts = $glacier->multipart_upload_list_parts( $vault, $upload_id );

=head2 calculate_multipart_upload_partsize ( $archive_size )

Calculates the part size that would allow to uploading files of $archive_size

$archive_size is the maximum expected archive size

Returns the smallest possible part size to upload an archive of
size $archive_size, 0 when files cannot be uploaded in parts (i.e. >39Tb)

=cut

sub calculate_multipart_upload_partsize {
	my ( $self, $archive_size ) = @_;

	# get the size of a part if uploaded in the maximum possible parts in MiB
	my $part_size = ( $archive_size - 1) / 10000;

	# the smallest power of 2 that fits this amount of MiB
	my $part_size_MiB_rounded = 2**(int(log($part_size)/log(2))+1);

	# range check response for minimum and maximum API limits
	if ( $part_size_MiB_rounded < 1024 * 1024 ) {
		# part size must be at least 1MiB
		return 1024 * 1024;
	} elsif ( $part_size_MiB_rounded > 4 * 1024 * 1024 * 1024 ) {
		# updated error severity
		croak 'part size must not exceed 4GiB, this file size is not uploadable';
	} else {
		return $part_size_MiB_rounded;
	}
}

=head2 multipart_upload_init( $vault_name, $part_size, [ $description ] )

Initiates a multipart upload.
$part_size should be carefully calculated to avoid dead ends as documented in
the API. Use calculate_multipart_upload_partsize.

Returns a multipart upload id that should be used while adding parts to the
online archive that is being constructed.

Multipart upload ids are valid until multipart_upload_abort is called or 24
hours after last archive related activity is registered. After that period id
validity should not be expected.

L<Initiate Multipart Upload (POST multipart-uploads)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-initiate-upload.html>.

=cut

sub multipart_upload_init {
	my ( $self, $vault_name, $part_size, $description) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no part size given" unless $part_size;
	croak "parameter number mismatch" unless @_ == 3 || @_ == 4;

	_enforce_description_limits( \$description );

	my $multipart_upload_id;

	my $res = $self->_send_receive(
		POST => "/-/vaults/$vault_name/multipart-uploads",
		[
			'x-amz-archive-description' => $description,
			'x-amz-part-size' => $part_size,
		],
	);
	# updated error severity
	croak 'multipart_upload_init failed with error ' . $res->status_line unless $res->is_success;

	$multipart_upload_id = $res->header('x-amz-multipart-upload-id');

	# double check the webservice speaks the same language
	# updated error severity
	croak 'request succeeded, but no multipart upload id was returned' unless ( $multipart_upload_id );

	return $multipart_upload_id;
}

=head2 multipart_upload_upload_part( $vault_name, $multipart_upload_id, $part_size, $part_index, $part )

Uploads a certain range of a multipart upload.

$part_size must be the same supplied to multipart_upload_init for a given
multipart upload.

$part_index should be the index of a file of N $part_size chunks whose data is
passed in $part.

$part can must be a reference to a string or be a filehandle and must be exactly
the part_size supplied to multipart_upload_initiate unless it is the last past
which can be any non-zero size.

Absolute maximum online archive size is 4GB*10000 or slightly over 39Tb.
L<Uploading Large Archives in Parts (Multipart Upload) Quick Facts|docs.aws.amazon.com/amazonglacier/latest/dev/uploading-archive-mpu.html#qfacts>

Returns uploaded part tree-hash (which should be store in an array ref to be
passed to multipart_upload_complete

L<Upload Part (PUT uploadID)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-upload-part.html>.

=cut

sub multipart_upload_upload_part {
	my ( $self, $vault_name, $multipart_upload_id, $part_size, $part_index, $part ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no multipart upload id given" unless $multipart_upload_id;
	croak "parameter number mismatch" unless @_ == 6;

	# identify $part as filehandle or string and get content
	my $content = '';

	if ( ref $part eq 'SCALAR' ) {
		# keep scalar reference
		$content = $part;
		croak "no data supplied" unless length $$content;
	} else {
		#try to read any other content as supported by File::Slurp
		eval {
			$content = File::Slurp::read_file( $part, bin_mode => ':raw', err_mode => 'carp', scalar_ref => 1 );
		};
		croak "\$part interpreted as file (GLOB, IO::Handle/File) but error occured while reading: $@" if ( $@ );

		croak "no data read from file" unless length $$content;
	}

	my $upload_part_size = length $$content;

	# compute part hash
	my $th = Net::Amazon::TreeHash->new();

	$th->eat_data( $content );

	$th->calc_tree();

	# range end must not be ( $part_size * ( $part_index + 1 ) - 1 ) or last part
	# will fail.
	my $res = $self->_send_receive(
		PUT => "/-/vaults/$vault_name/multipart-uploads/$multipart_upload_id",
		[
			'Content-Range' => 'bytes ' . ( $part_size * $part_index ) . '-' .  ( ( $part_size * $part_index ) + $upload_part_size - 1 ) . '/*',
			'Content-Length' => $upload_part_size,
			'Content-Type' => 'application/octet-stream',
			'x-amz-sha256-tree-hash' => $th->get_final_hash(),
			'x-amz-content-sha256' => Digest::SHA::sha256_hex( $$content ),
			# documentation seems to suggest x-amz-content-sha256 may not be needed but it is!
		],
		$$content
	);
	# updated error severity
	croak 'multipart_upload_upload_part failed with error ' . $res->status_line unless $res->is_success;

	# check glacier tree-hash = local tree-hash
	# updated error severity; multipart upload id must be returned
	croak 'request succeeded, but reported and computed tree-hash for part do not match' unless ( $th->get_final_hash() eq $res->header('x-amz-sha256-tree-hash') );
	# return computed tree-hash for this part
	return $res->header('x-amz-sha256-tree-hash');
}

=head2 multipart_upload_complete( $vault_name, $multipart_upload_id, $tree_hash_array_ref, $archive_size )

Signals completion of multipart upload.

$tree_hash_array_ref must be an ordered list (same order as final assembled online
archive, as opposed to upload order) of partial tree hashes as returned by
multipart_upload_upload_part

$archive_size is provided at completion to check all parts make up an archive an
not before hand to allow for archive streaming a.k.a. upload archives of unknown
size. Beware of dead ends when choosing part size. Use
calculate_multipart_upload_partsize to select a part size that will work.

Returns an archive id that can be used to request a job to retrieve the archive
at a later time on success and 0 on failure.

On failure multipart_upload_list_parts could be used to determine the missing
part or recover the partial tree hashes, complete the missing parts and
recalculate the correct archive tree hash and call multipart_upload_complete
with a successful result.

L<Complete Multipart Upload (POST uploadID)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-complete-upload.html>.

=cut

sub multipart_upload_complete {
	my ( $self, $vault_name, $multipart_upload_id, $tree_hash_array_ref, $archive_size ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no multipart upload id given" unless $multipart_upload_id;
	croak "no tree hash object given" unless ref $tree_hash_array_ref eq 'ARRAY';
	croak "parameter number mismatch" unless @_ == 5;

	my $archive_tree_hash = $self->_tree_hash_from_array_ref( $tree_hash_array_ref );

	my $res = $self->_send_receive(
		POST => "/-/vaults/$vault_name/multipart-uploads/$multipart_upload_id",
		[
			'x-amz-sha256-tree-hash' => $archive_tree_hash ,
			'x-amz-archive-size' => $archive_size,
		],
	);
	# updated error severity
	croak 'multipart_upload_complete failed with error ' . $res->status_line unless $res->is_success;

	my $rec_archive_id;
	unless ( $res->header('location') =~ m{^/[^/]+/vaults/[^/]+/archives/(.*)$} ) {
		# update severity of error. This method must return an archive id
		croak 'request succeeded, but reported archive location does not match regex: ' . $res->header('location');
	} else {
		$rec_archive_id = $1;
	}

	return $rec_archive_id;
}

=head2 multipart_upload_abort( $vault_name, $multipart_upload_id )

Aborts multipart upload releasing the id and related online resources of
a partially uploaded archive.

L<Abort Multipart Upload (DELETE uploadID)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-abort-upload.html>.

=cut

sub multipart_upload_abort {
	my ( $self, $vault_name, $multipart_upload_id ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no multipart_upload_id given" unless $multipart_upload_id;
	croak "parameter number mismatch" unless @_ == 3;

	my $res = $self->_send_receive(
		DELETE => "/-/vaults/$vault_name/multipart-uploads/$multipart_upload_id",
	);
	# updated error severity
	croak 'multipart_upload_abort failed with error ' . $res->status_line unless $res->is_success;

	# double check the webservice speaks the same language
	# updated error severity
	croak 'request returned an invalid code' unless ( $res->code == 204 );

	return $res->is_success;
}

=head2 multipart_upload_list_parts ( $vault_name, $multipart_upload_id )

Returns an array ref with information on all uploaded parts of the, probably
partially uploaded, online archive.

Useful to recover file part tree hashes and complete a broken multipart upload.

L<List Parts (GET uploadID)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-parts.html>

A call to multipart_upload_part_list can result in many calls to the
Amazon API at a rate of 1 per 1,000 recently completed job in existence.
Calls to List Parts in the API are L<free|http://aws.amazon.com/glacier/pricing/#storagePricing>.

=cut

sub multipart_upload_list_parts {
	my ( $self, $vault_name, $multipart_upload_id ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no multipart_upload_id given" unless $multipart_upload_id;
	croak "parameter number mismatch" unless @_ == 3;

	my @upload_part_list;

	my $marker;
	do {
		#1000 is the default limit, send a marker if needed
		my $res = $self->_send_receive( GET => "/-/vaults/$vault_name/multipart-uploads/$multipart_upload_id?limit=1000" . ($marker?'&'.$marker:'') );
		# updated error severity
		croak 'multipart_upload_list_parts failed with error ' . $res->status_line unless $res->is_success;
		my $decoded = $self->_decode_and_handle_response( $res );

		push @upload_part_list, @{$decoded->{Parts}};
		$marker = $decoded->{Marker};
	} while ( $marker );

	return \@upload_part_list;
}

=head2 multipart_upload_list_uploads( $vault_name )

Returns an array ref with information on all non completed multipart uploads.
Useful to recover multipart upload ids.
L<List Multipart Uploads (GET multipart-uploads)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-multipart-list-uploads.html>

A call to multipart_upload_list can result in many calls to the Amazon API
at a rate of 1 per 1,000 recently completed job in existence.
Calls to List Multipart Uploads in the API are L<free|http://aws.amazon.com/glacier/pricing/#storagePricing>.

=cut

sub multipart_upload_list_uploads {
	my ( $self, $vault_name ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "parameter number mismatch" unless @_ == 2;

	my @upload_list;

	my $marker;
	do {
		#1000 is the default limit, send a marker if needed
		my $res = $self->_send_receive( GET => "/-/vaults/$vault_name/multipart-uploads?limit=1000" . ($marker?'&'.$marker:'') );
		# updated error severity
		croak 'multipart_upload_list_uploads failed with error ' . $res->status_line unless $res->is_success;
		my $decoded = $self->_decode_and_handle_response( $res );

		push @upload_list, @{$decoded->{UploadsList}};
		$marker = $decoded->{Marker};
	} while ( $marker );

	return \@upload_list;
}

=head1 JOB OPERATIONS

=head2 initiate_archive_retrieval( $vault_name, $archive_id, [
$description, $sns_topic ] )

Initiates an archive retrieval job. $archive_id is an ID previously
retrieved from Amazon Glacier.

A job description of up to 1,024 printable ASCII characters may be supplied.
Net::Amazon::Glacier does it's best to enforce this restriction. When unsure
send the string and look for Carp.

An SNS Topic to send notifications to upon job completion may also be supplied.

L<Initiate a Job (POST jobs)|docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html#api-initiate-job-post-requests-syntax>.

=cut

sub initiate_archive_retrieval {
	my ( $self, $vault_name, $archive_id, $description, $sns_topic ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no archive id given" unless $archive_id;

	my $content_raw = {
		Type => 'archive-retrieval',
		ArchiveId => $archive_id,
	};

	if ( defined $description ) {
		 _enforce_description_limits( \$description );
		$content_raw->{Description} = $description;
	}

	$content_raw->{SNSTopic} = $sns_topic
		if defined($sns_topic);

	my $res = $self->_send_receive(
		POST => "/-/vaults/$vault_name/jobs",
		[ ],
		encode_json($content_raw),
	);
	# updated error severity; method must return a job id
	croak 'initiate_archive_retrieval failed with error ' . $res->status_line unless $res->is_success;

	return $res->header('x-amz-job-id');
}

=head2 initiate_inventory_retrieval( $vault_name, $format, [ $description,
$sns_topic ] )

Initiates an inventory retrieval job. $format is either CSV or JSON.

A job description of up to 1,024 printable ASCII characters may be supplied.
Net::Amazon::Glacier does it's best to enforce this restriction. When unsure
send the string and look for Carp.

An SNS Topic to send notifications to upon job completion may also be supplied.

L<Initiate a Job (POST jobs)|docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html#api-initiate-job-post-requests-syntax>.

=cut

sub initiate_inventory_retrieval {
	my ( $self, $vault_name, $format, $description, $sns_topic ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no format given" unless $format;

	my $content_raw = {
		Type => 'inventory-retrieval',
	};

	$content_raw->{Format} = $format
		if defined($format);

	if ( defined $description ) {
		_enforce_description_limits( \$description );
		$content_raw->{Description} = $description;
	}

	$content_raw->{SNSTopic} = $sns_topic
		if defined($sns_topic);

	my $res = $self->_send_receive(
		POST => "/-/vaults/$vault_name/jobs",
		[ ],
		encode_json($content_raw),
	);
	# updated error severity; method must return a job id
	croak 'initiate_inventory_retrieval failed with error ' . $res->status_line unless $res->is_success;

	return $res->header('x-amz-job-id');
}

=head2 initiate_job( ( $vault_name, $archive_id, [ $description, $sns_topic ] )

Effectively calls initiate_inventory_retrieval.

Exists for the sole purpose or implementing the Amazon Glacier Developer Guide (API Version 2012-06-01)
nomenclature.

L<Initiate a Job (POST jobs)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-initiate-job-post.html>.

=cut

sub initiate_job {
	initiate_inventory_retrieval( @_ );
}

=head2 describe_job( $vault_name, $job_id )

Retrieves a hashref with information about the requested JobID.

L<Amazon Glacier Describe Job (GET JobID)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-describe-job-get.html>.

=cut

sub describe_job {
	my ( $self, $vault_name, $job_id ) = @_;
	my $res = $self->_send_receive( GET => "/-/vaults/$vault_name/jobs/$job_id" );
	# updated error severity
	croak 'describe_job failed with error ' . $res->status_line unless $res->is_success;
	return $self->_decode_and_handle_response( $res );
}

=head2 get_job_output( $vault_name, $job_id, [ $range ] )

Retrieves the output of a job, returns a binary blob. Optional range
parameter is passed as an HTTP header.
L<Amazon Glacier Get Job Output (GET output)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-job-output-get.html>.

If you pass a range parameter, you're going to want the tree-hash for your
chunk.  That will be returned in an additional return value, so collect it
like this:

	($bytes, $tree_hash) = get_job_output(...)

=cut

sub get_job_output {
	my ( $self, $vault_name, $job_id, $range ) = @_;

	croak "no vault name given" unless $vault_name;
	croak "no job id given" unless $vault_name;

	my $headers = [];

	push @$headers, (Range => $range)
		if defined($range);

	my $res = $self->_send_receive( GET => "/-/vaults/$vault_name/jobs/$job_id/output", $headers );
	# updated error severity
	croak 'get_job_output failed with error ' . $res->status_line unless $res->is_success;

	return wantarray ? ($res->decoded_content, $res->header('x-amz-sha256-tree-hash')) : $res->decoded_content;
}

=head2 list_jobs( $vault_name )

Return an array with information about all recently completed jobs for the
specified vault.
L<Amazon Glacier List Jobs (GET jobs)|http://docs.aws.amazon.com/amazonglacier/latest/dev/api-jobs-get.html>.

A call to list_jobs can result in many calls to the Amazon API at a rate of
1 per 1,000 recently completed job in existence.
Calls to List Jobs in the API are L<free|http://aws.amazon.com/glacier/pricing/#storagePricing>.

=cut

sub list_jobs {
	my ( $self, $vault_name ) = @_;

	croak "no vault name given" unless $vault_name;

	my @completed_jobs;

	my $marker;
	do {
		#1000 is the default limit, send a marker if needed
		my $res = $self->_send_receive( GET => "/-/vaults/$vault_name/jobs?limit=1000" . ($marker?'&'.$marker:'') );
		# updated error severity
		croak 'list_jobs failed with error ' . $res->status_line unless $res->is_success;
		my $decoded = $self->_decode_and_handle_response( $res );

		push @completed_jobs, @{$decoded->{JobList}};
		$marker = $decoded->{Marker};
	} while ( $marker );

	return ( \@completed_jobs );
}

# helper functions

# receives an array ref of hex strings as returned by multipart_upload_upload_part
# the array ref must be in the resulting online archive order as oppossed to the
# upload order
# returns an hex string representing the tree hash of the complete archive for
# use in multipart_upload_complete
sub _tree_hash_from_array_ref {
	my ( $self, $tree_hash_array_ref ) = @_;

	croak "no tree hash object given" unless $tree_hash_array_ref;
	croak "tree hash array ref is not an array reference" unless ref $tree_hash_array_ref eq 'ARRAY';
	croak "tree hash array ref does not seem to contain sha256 hex strings" unless
		length join ('', map m/^[0-9a-fA-F]{64}$/, @$tree_hash_array_ref) == scalar @$tree_hash_array_ref;

	# copy array to temporary array mapped to byte values
	my @prevLvlHashes = map( pack("H*", $_), @{$tree_hash_array_ref} );

	# consume parts in pairs A (+) B until we have one part (unrolled recursive)
	while ( @prevLvlHashes > 1 ) {
		my ( $prevLvlIterator, $currLvlIterator );

		my @currLvlHashes;

		# consume two elements form previous level to make for one element of the
		# next level, last elements on odd sized arrays copied verbatim to next level
		for ( $prevLvlIterator = 0, $currLvlIterator = 0; $prevLvlIterator < @prevLvlHashes; $prevLvlIterator+=2 ) {
			if ( @prevLvlHashes - $prevLvlIterator > 1) {
				# store digest in next level as byte values
				push @currLvlHashes, Digest::SHA::sha256( $prevLvlHashes[ $prevLvlIterator ], $prevLvlHashes[ $prevLvlIterator + 1 ] );
			} else {
				push @currLvlHashes, $prevLvlHashes[ $prevLvlIterator ];
			}
		}

		# advance one level
		@prevLvlHashes = @currLvlHashes;
	}

	# return resulting array as string of hex values
	return unpack( 'H*', $prevLvlHashes[0] );
}

sub _decode_and_handle_response {
	my ( $self, $res ) = @_;

	if ( $res->is_success ) {
		return decode_json( $res->decoded_content );
	} else {
		return undef;
	}
}

sub _send_receive {
	my $self = shift;
	my $req = $self->_craft_request( @_ );
	return $self->_send_request( $req );
}

sub _craft_request {
	my ( $self, $method, $url, $header, $content ) = @_;
	my $host = 'glacier.'.$self->{region}.'.amazonaws.com';
	my $total_header = [
		'x-amz-glacier-version' => '2012-06-01',
		'Host' => $host,
		'Date' => POSIX::strftime( '%Y%m%dT%H%M%SZ', gmtime ),
		$header ? @$header : ()
	];
	my $req = HTTP::Request->new( $method => "https://$host$url", $total_header, $content);
	my $signed_req = $self->{sig}->sign( $req );
	return $signed_req;
}

sub _send_request {
	my ( $self, $req ) = @_;
	my $res = $self->{ua}->request( $req );
	if ( $res->is_error ) {
		# try to decode Glacier error
		eval {
			my $error = decode_json( $res->decoded_content );
			carp sprintf 'Non-successful response: %s (%s)', $res->status_line, $error->{code};
			carp decode_json( $res->decoded_content )->{message};
		};
		if ( $@ ) {
			# fall back to reporting ua errors
			carp sprintf "[%d] %s %s\n", $res->code, $res->message, $res->decoded_content;
		}
	}
	return $res;
}

sub _enforce_description_limits {
	my ( $description ) = @_;
	croak 'Description should be a reference so that I can enforce limits on it.' unless ref $description eq 'SCALAR';
	# order is important. We do not want to loose any characters unless needed.
	my $changes = ( $$description =~ tr/\x20-\x7f//cd );
	carp 'Description contains invalid characters stick to printable ASCII (x20-x7f). Fixed.' if ( $changes );
	if ( length $$description > 1024 ) {
		$$description = substr( $$description, 0, 1024 );
		carp 'Description should not be longer than 1024 characters. Fixed.';
	}

	return $description;
}

=head1 ROADMAP

=over 4

=item * Online tests.

=item * Implement a "simple" interfase in the lines of

		use Net::Amazon::Glacier;

		# Bless and upload something
		my $glacier = Net::Amazon::Glacier->new( $region, $aws_key, $aws_secret, $metadata_store );

		# Upload intelligently, i.e. in resumable parts, split very big files.
		$glacier->simple->upload( $path || $scalar_ref || $some_fh );

		# Support automatic archive_id to some description conversion
		# Ask for a job when first called, return while it is not ready,
		# return content when ready.
		$glacier->simple->download( $archive_id || 'description', [ $ranges ] );

		# Request download and spawn something, wait and execute $some_code_ref
		# when content ready.
		$glacier->simple->download_wait( $archive_id || 'description' , $some_code_ref, [ $ranges ] );

		# Delete online archive
		$glacier->simple->delete( $archive_id || 'description' );

=item * Implement a simple command line cli with access to simple interface.

		glacier new us-east-1 AAIKSAKS... sdoasdod... /metadata/file
		glacier upload /some/file
		glacier download /some/file (this would spawn a daemon waiting for download)
		glacier ls

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Amazon::Glacier

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Amazon-Glacier>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Amazon-Glacier>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Amazon-Glacier>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Amazon-Glacier/>

=item * Check the GitHub repo, development branches in particular.

L<https://github.com/gbarco/Net-Amazon-Glacier>

=item * Mail Gonzalo Barco

C<< <gbarco uy at gmail com, no spaces> >>

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-amazon-glacier at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Amazon-Glacier>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

See also Victor Efimov's MT::AWS::Glacier, an application for AWS Glacier
synchronization. It is available at L<https://github.com/vsespb/mt-aws-glacier>.

=head1 AUTHORS

Originally written by Tim Nordenfur, C<< <tim at gurka.se> >>.
Maintained by Gonzalo Barco C<< <gbarco uy at gmail com, no spaces> >>
Support for job operations was contributed by Ted Reed at IMVU.
Support for many file operations and multipart uploads by Gonzalo Barco.
Bugs, suggestions and fixes contributed by Victor Efimov and Kevin Goess.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Tim Nordenfur.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Net::Amazon::Glacier
