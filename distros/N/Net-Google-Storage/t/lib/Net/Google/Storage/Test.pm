package Net::Google::Storage::Test;
use base qw(Test::Class);

use Net::Google::Storage;

use autodie;
use Test::More;
use JSON;
use File::Temp qw(tempfile);
use Digest::MD5;

sub _read_config : Test(startup)
{
	my $self = shift;
	
	$self->SKIP_ALL('No config file available') unless -e '../../config.json';
	open(my $fh, '<', '../../config.json');
	
	my $contents = join '', <$fh>;
	close $fh;
	
 	$self->{config} = decode_json($contents);
}

sub new_gs : Test(startup => 1)
{
	my $self = shift;
	my $config = $self->{config};
	$self->{gs} = Net::Google::Storage->new(
		client_id =>	 $config->{client_id},
		client_secret => $config->{client_secret},
		refresh_token => $config->{refresh_token},
		projectId =>	 $config->{projectId},
	);
	isa_ok($self->{gs}, 'Net::Google::Storage') or $self->BAILOUT('Unable to create Net::Google::Storage object');
}

sub _access_token_refresh : Test(5)
{
	my $self = shift;
	my $gs = $self->{gs};
	
	ok(!$gs->access_token, 'Access token does not exist');
	ok(!$gs->has_refreshed_access_token, 'Access token is not yet marked as refreshed');
	
	$gs->refresh_access_token;
	
	ok($gs->access_token, 'Access token exists');
	ok($gs->has_refreshed_access_token, 'Access token is marked as refreshed');
	
	my $expiry = $gs->access_token_expiry;
	cmp_ok($expiry, '>', time, 'Access token is set to expire in the future');
}

sub bucket_1_view : Test(6)
{
	my $self = shift;
	my $gs = $self->{gs};
	
	my $buckets = $gs->list_buckets;
	
	ok($buckets && @$buckets, 'We got at least one bucket');
	
	my $desired_bucket_name = $self->{config}->{test_bucket}->{name};
	my $desired_bucket_created = $self->{config}->{test_bucket}->{created};
	
	my @desired_buckets = grep {$_->id eq $desired_bucket_name} @$buckets;
	cmp_ok(scalar @desired_buckets, '==', 1, "We matched exactly one bucket for $desired_bucket_name");
	
	my $desired_bucket = $desired_buckets[0];
	isa_ok($desired_bucket, 'Net::Google::Storage::Bucket');
	is($desired_bucket->id, $desired_bucket_name);
	is($desired_bucket->timeCreated, $desired_bucket_created);
	
	my $explicitly_requested_bucket = $gs->get_bucket($desired_bucket_name);
	is_deeply($explicitly_requested_bucket, $desired_bucket)
}

sub bucket_2_create : Test(6)
{
	my $self = shift;
	my $gs = $self->{gs};
	my $config = $self->{config};
	
	my $new_bucket_name = $config->{new_test_bucket}->{name};
	return 'No configs for creating buckets' unless $new_bucket_name;
	
	my $existing_bucket = $gs->get_bucket($new_bucket_name);
	is($existing_bucket, undef, 'Bucket does not exist yet') or return "Test bucket $new_bucket_name already exists";
	
	my $bucket = $gs->insert_bucket({id => $new_bucket_name});
	isa_ok($bucket, 'Net::Google::Storage::Bucket');
	is($bucket->id, $new_bucket_name);
	
	$bucket = undef;
	is($bucket, undef, 'Unset the bucket variable prior to refetching');
	$bucket = $gs->get_bucket($new_bucket_name);
	isa_ok($bucket, 'Net::Google::Storage::Bucket');
	is($bucket->id, $new_bucket_name);
}

sub bucket_3_delete : Test(3)
{
	my $self = shift;
	my $gs = $self->{gs};
	my $config = $self->{config};

	my $new_bucket_name = $config->{new_test_bucket}->{name};
	return 'No configs for creating buckets' unless $new_bucket_name;
	
	my $bucket = $gs->get_bucket($new_bucket_name);
	isa_ok($bucket, 'Net::Google::Storage::Bucket');
	is($bucket->id, $new_bucket_name);
	
	$gs->delete_bucket($new_bucket_name);
	
	$bucket = $gs->get_bucket($new_bucket_name);
	is($bucket, undef, 'Successfully gotten rid of the bucket')
}

sub object_1_view : Test(4)
{
	my $self = shift;
	my $gs = $self->{gs};
	my $config = $self->{config};
	
	my $test_bucket_name = $self->{config}->{test_bucket}->{name};
	my $test_object_name = $self->{config}->{test_bucket}->{known_object}->{name};
	
	my $existing_object = $gs->get_object(bucket => $test_bucket_name, object => $test_object_name);
	isa_ok($existing_object, 'Net::Google::Storage::Object');
	is($existing_object->name, $test_object_name);
	my $media = $existing_object->media;
	is($media->{timeCreated}, $self->{config}->{test_bucket}->{known_object}->{created});
	if($media->{algorithm} eq 'MD5')
	{
		is($media->{hash}, $self->{config}->{test_bucket}->{known_object}->{md5sum}, 'MD5 hash matches metadata');
	}
	else
	{
		ok(1, "No point comparing the hashes");
	}
}

sub object_2_download : Test(2)
{
	my $self = shift;
	my $gs = $self->{gs};
	my $config = $self->{config};
	
	my $test_bucket_name = $self->{config}->{test_bucket}->{name};
	my $test_object_name = $self->{config}->{test_bucket}->{known_object}->{name};
	my ($fh, $filename) = tempfile(UNLINK => 1);
	
	$gs->download_object(bucket => $test_bucket_name, object => $test_object_name, filename => $filename);
	ok(-e $filename);
	my $ctx = Digest::MD5->new;
	$ctx->addfile($fh);
	is($ctx->hexdigest, $self->{config}->{test_bucket}->{known_object}->{md5sum}, 'MD5 hash matches downloaded file');
}

sub object_3_list : Test(3)
{
	my $self = shift;
	my $gs = $self->{gs};
	my $config = $self->{config};
	
	my $test_bucket_name = $self->{config}->{test_bucket}->{name};
	my $test_object_name = $self->{config}->{test_bucket}->{known_object}->{name};
	
	my $objects = $gs->list_objects($test_bucket_name);
	my @desired_objects = grep {$_->name eq $test_object_name} @$objects;
	cmp_ok(scalar @desired_objects, '==', 1, "We matched exactly one object for $test_object_name");
	
	my $object = $desired_objects[0];
	isa_ok($object, 'Net::Google::Storage::Object');
	
	is($object->selfLink, $gs->get_object(bucket => $test_bucket_name, object => $test_object_name)->selfLink);
}

sub object_4_upload : Test(5)
{
	my $self = shift;
	my $gs = $self->{gs};
	my $config = $self->{config};
	
	my $test_bucket_name = $self->{config}->{test_bucket}->{name};
	my $filename = $self->{config}->{test_bucket}->{upload_object}->{name};
	
	is($gs->get_object(bucket => $test_bucket_name, object => $filename), undef) or return "$filename already exists";
	
	my $new_object = $gs->insert_object(bucket => $test_bucket_name, object => {name => $filename, media => {}}, filename => $filename);
	isa_ok($new_object, 'Net::Google::Storage::Object');
	is($new_object->name, $filename);
	my $media = $new_object->media;
	if($media->{algorithm} eq 'MD5')
	{
		my $ctx = Digest::MD5->new;
		open(my $fh, '<', $filename);
		$ctx->addfile($fh);
		is($media->{hash}, $ctx->hexdigest, 'MD5 hash metadata matches uploaded file');
	}
	else
	{
		ok(1, "Unable to check nonexistent metadata")
	}
	
	my $same_object = $gs->get_object(bucket => $test_bucket_name, object => $filename);
	is_deeply($same_object, $new_object);
}

sub object_5_delete : Test(3)
{
	my $self = shift;
	my $gs = $self->{gs};
	my $config = $self->{config};
	
	my $test_bucket_name = $self->{config}->{test_bucket}->{name};
	my $filename = $self->{config}->{test_bucket}->{upload_object}->{name};
	
	my $object = $gs->get_object(bucket => $test_bucket_name, object => $filename);
	isa_ok($object, 'Net::Google::Storage::Object');
	is($object->name, $filename);
	
	$gs->delete_object(bucket => $test_bucket_name, object => $filename);
	$object = $gs->get_object(bucket => $test_bucket_name, object => $filename);
	is($object, undef, 'Successfully gotten rid of the object');
}

1;
