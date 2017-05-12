package RWDE::DB::BigFile;

use strict;
use warnings;

use Error qw(:try);

use RWDE::Configuration; 
use RWDE::Exceptions;
use RWDE::DB::S3;


use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 554 $ =~ /(\d+)/;

sub s3_put {
	my ($self, $params) = @_;

	my %S3_hash = $self->get_s3_hash();

	while ( my ($field, $key) = each(%S3_hash) ) {
		$self->Put({ key_name => $key, content_type => $self->image_filetype, content => $self->$field });
	}
	
	return();
}

sub s3_delete {
	my ($self, $params) = @_;

	my %S3_hash = $self->get_s3_hash();

	while ( my ($field, $key) = each(%S3_hash) ) {
	$self->Delete({ key_name => $key });	}

  return();
}

sub s3_get {
	my ($self, $params) = @_;

	my %S3_hash = $self->get_s3_hash();
  my $field = $$params{field_name} || 'image_data';
	return $self->Get({ key_name => $S3_hash{$field} });
}

sub s3_publicRead {
	my ($self, $params) = @_;
	my %S3_hash = $self->get_s3_hash();

	while ( my ($field, $key) = each(%S3_hash) ) {
		$self->Put({ key_name => $key, content_type => $self->image_filetype, content => $self->get_data(), acl => 'public-read' });
	}
}

sub s3_noPublicRead {
	my ($self, $params) = @_;
	my %S3_hash = $self->get_s3_hash();

	while ( my ($field, $key) = each(%S3_hash) ) {
		$self->Put({ key_name => $key, content_type => $self->image_filetype, content => $self->get_data(), acl => 'private' });
	}
}

sub Put {
	my ($self, $params) = @_;

	my $s3 = RWDE::DB::S3->new();

        use CGI;
        $s3->putObject(RWDE::Configuration->S3BucketName, CGI::escape($$params{key_name}), $$params{content_type}, $$params{content}, 
$$params{acl});
	
	return();
}

sub Delete {
	my ($self, $params) = @_;

	my $s3 = RWDE::DB::S3->new();

  $s3->deleteObject(RWDE::Configuration->S3BucketName, $$params{key_name});

	return();
}

sub Get {
	my ($self, $params) = @_;

	my $s3 = RWDE::DB::S3->new();

  my $response = $s3->getObject(RWDE::Configuration->S3BucketName, $$params{key_name});
	
	return $response->content;
}


1;

