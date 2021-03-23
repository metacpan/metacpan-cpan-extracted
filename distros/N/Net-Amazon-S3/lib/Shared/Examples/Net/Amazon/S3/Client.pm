package Shared::Examples::Net::Amazon::S3::Client;
# ABSTRACT: used for testing and as example
$Shared::Examples::Net::Amazon::S3::Client::VERSION = '0.98';
use strict;
use warnings;

use parent qw[ Exporter::Tiny ];

use Hash::Util;
use HTTP::Response;
use HTTP::Status;
use Sub::Override;
use Test::Deep;
use Test::More;

use Net::Amazon::S3::Client;
use Shared::Examples::Net::Amazon::S3;

our @EXPORT_OK = (
	qw[ expect_signed_uri ],
	qw[ expect_client_list_all_my_buckets ],
	qw[ expect_client_bucket_acl_get ],
	qw[ expect_client_bucket_acl_set ],
	qw[ expect_client_bucket_create ],
	qw[ expect_client_bucket_delete ],
	qw[ expect_client_bucket_objects_delete ],
	qw[ expect_client_bucket_objects_list ],
	qw[ expect_client_bucket_tags_add ],
	qw[ expect_client_bucket_tags_delete ],
	qw[ expect_client_object_acl_set ],
	qw[ expect_client_object_create ],
	qw[ expect_client_object_delete ],
	qw[ expect_client_object_fetch ],
	qw[ expect_client_object_head ],
	qw[ expect_client_object_tags_add],
	qw[ expect_client_object_tags_delete],
);

*with_fixture = *Shared::Examples::Net::Amazon::S3::with_fixture;

sub _exporter_expand_sub {
	my ($self, $name, $args, $globals) = @_;

	my $s3_operation = $name;
	$s3_operation =~ s/_client_/_operation_/;

	return +( $name => eval <<"GEN_SUB" );
		sub {
			push \@_, -shared_examples => __PACKAGE__;
			goto \\& Shared::Examples::Net::Amazon::S3::$s3_operation;
		}
GEN_SUB
}

sub _default_with_api {
	my ($self, $params) = @_;

	$params->{with_client} ||= Net::Amazon::S3::Client->new (
		s3 => Shared::Examples::Net::Amazon::S3::s3_api_with_signature_2 ()
	);
}

sub _mock_http_response {
	my ($self, $api, %params) = @_;

	Shared::Examples::Net::Amazon::S3->s3_api_mock_http_response (
		$api->s3,
		%params,
	)
}

sub expect_signed_uri {
	my ($title, %params) = @_;

	Hash::Util::lock_keys %params,
		qw[ with_client ],
		qw[ with_bucket ],
		qw[ with_region ],
		qw[ with_key ],
		qw[ with_expire_at ],
		qw[ with_method ],
		qw[ expect_uri ],
		;

	my $guard = Sub::Override->new (
		'Net::Amazon::S3::Bucket::region' => sub { $params{with_region } },
	);

	my $got = $params{with_client}
		->bucket (
			name    => $params{with_bucket},
		)
		->object (
			key     => $params{with_key},
			expires => $params{with_expire_at},
		)
		->query_string_authentication_uri_for_method (
			$params{with_method} || 'GET',
		)
		;

	cmp_deeply $got, $params{expect_uri}, $title;
}

sub operation_list_all_my_buckets {
	my ($self, %params) = @_;

	[ $_[0]->buckets ];
}

sub operation_bucket_acl_get {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->acl
		;
}

sub operation_bucket_create {
	my ($self, %params) = @_;

	$self->create_bucket(
		name => $params{with_bucket},
		(acl       => $params{with_acl})       x!! exists $params{with_acl},
		(acl_short => $params{with_acl_short}) x!! exists $params{with_acl_short},
		(location_constraint => $params{with_region}) x!! exists $params{with_region},
	);
}

sub operation_bucket_delete {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->delete
		;
}

sub operation_bucket_objects_list {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->list ({
			bucket      => $params{with_bucket},
			delimiter   => $params{with_delimiter},
			max_keys    => $params{with_max_keys},
			marker      => $params{with_marker},
			prefix      => $params{with_prefix},
		})
		;
}

sub operation_bucket_objects_delete {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->delete_multi_object (@{ $params{with_keys} })
		;
}

sub operation_object_create {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->object (
			key => $params{with_key},
			map +($_ => $params{"with_$_"}),
			grep exists $params{"with_$_"}, (
				qw[ cache_control  ],
				qw[ content_disposition  ],
				qw[ content_encoding  ],
				qw[ content_type  ],
				qw[ encryption ],
				qw[ expires ],
				qw[ storage_class ],
				qw[ user_metadata ],
				qw[ acl ],
				qw[ acl_short ],
			)
		)
		->${\ (ref $params{with_value} ? 'put_filename' : 'put' ) } (
			ref $params{with_value} ? ${ $params{with_value} } : $params{with_value}
		)
		;
}

sub operation_object_delete {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->object (key => $params{with_key})
		->delete
		;
}

sub operation_object_fetch {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->object (key => $params{with_key})
		->get
		;
}

sub operation_object_head {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->object (key => $params{with_key})
		->exists
		;
}

sub operation_bucket_acl_set {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->set_acl (
			(acl       => $params{with_acl})       x!! exists $params{with_acl},
			(acl_short => $params{with_acl_short}) x!! exists $params{with_acl_short},
			(acl_xml   => $params{with_acl_xml})   x!! exists $params{with_acl_xml},
		)
		;
}

sub operation_object_acl_set {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->object (key => $params{with_key})
		->set_acl (
			(acl       => $params{with_acl})       x!! exists $params{with_acl},
			(acl_short => $params{with_acl_short}) x!! exists $params{with_acl_short},
			(acl_xml   => $params{with_acl_xml})   x!! exists $params{with_acl_xml},
		)
		;
}

sub operation_bucket_tags_add {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->add_tags (
			tags => $params{with_tags},
		)
		;
}

sub operation_object_tags_add {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->object (key => $params{with_key})
		->add_tags (
			tags => $params{with_tags},
			(version_id => $params{with_version_id}) x!! defined $params{with_version_id},
		)
		;
}

sub operation_bucket_tags_delete {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->delete_tags
		;
}

sub operation_object_tags_delete {
	my ($self, %params) = @_;

	$self
		->bucket (name => $params{with_bucket})
		->object (key => $params{with_key})
		->delete_tags (
			(version_id => $params{with_version_id}) x!! defined $params{with_version_id},
		)
		;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Client - used for testing and as example

=head1 VERSION

version 0.98

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
