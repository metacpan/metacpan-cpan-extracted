package Shared::Examples::Net::Amazon::S3;
# ABSTRACT: used for testing and as example
$Shared::Examples::Net::Amazon::S3::VERSION = '0.99';
use strict;
use warnings;

use parent qw[ Exporter::Tiny ];

use Hash::Util;
use Ref::Util (
	qw[ is_regexpref ],
);

use Test::Deep;
use Test::More;
use Test::LWP::UserAgent;

use Net::Amazon::S3;

use Shared::Examples::Net::Amazon::S3::API;
use Shared::Examples::Net::Amazon::S3::Client;
use Shared::Examples::Net::Amazon::S3::Request;

our @EXPORT_OK = (
	qw[ s3_api_with_signature_4 ],
	qw[ s3_api_with_signature_2 ],
	qw[ expect_net_amazon_s3_feature ],
	qw[ expect_net_amazon_s3_operation ],
	qw[ expect_operation_list_all_my_buckets ],
	qw[ expect_operation_bucket_create ],
	qw[ expect_operation_bucket_delete ],
	qw[ with_fixture ],
	qw[ fixture ],
	qw[ with_response_fixture ],
);

my %fixtures;
sub fixture {
	my ($name) = @_;

	$fixtures{$name} = eval "require Shared::Examples::Net::Amazon::S3::Fixture::$name"
		unless defined $fixtures{$name};

	die "Fixture $name not found: $@"
		unless defined $fixtures{$name};

	return +{ %{ $fixtures{$name} } };
}

sub with_fixture {
	my ($name) = @_;

	my $fixture = fixture ($name);
	return wantarray
		? %$fixture
		: $fixture
		;
}

sub with_response_fixture {
	my ($name) = @_;

	my $fixture = fixture ($name);
	my $response_fixture = {};

	for my $key (keys %$fixture) {
		my $new_key;
		$new_key ||= "with_response_data" if $key eq 'content';
		$new_key ||= "with_$key" if $key =~ m/^response/;
		$new_key ||= "with_response_header_$key";

		$response_fixture->{$new_key} = $fixture->{$key};
	}

	return wantarray
		? %$response_fixture
		: $response_fixture
		;
}


sub s3_api {
	my $api = Net::Amazon::S3->new (@_);

	$api->ua (Test::LWP::UserAgent->new (network_fallback => 0));

	$api;
}

sub s3_api_mock_http_response {
	my ($self, $api, %params) = @_;

	$params{with_response_code} ||= HTTP::Status::HTTP_OK;

	my %headers = (
		content_type => 'application/xml',
		(
			map {
				m/^with_response_header_(.*)/;
				defined $1 && length $1
					? ($1 => $params{$_})
					: ()
			} keys %params
		),
		%{ $params{with_response_headers} || {} },
	);

	$api->ua->map_response (
		sub {
			${ $params{into} } = $_[0];
			1;
		},
		HTTP::Response->new (
			$params{with_response_code},
			HTTP::Status::status_message ($params{with_response_code}),
			[ %headers ],
			$params{with_response_data},
		),
	);
}

sub s3_api_with_signature_4 {
	s3_api (
		@_,
		aws_access_key_id     => 'AKIDEXAMPLE',
		aws_secret_access_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
		authorization_method  => 'Net::Amazon::S3::Signature::V4',
		secure                => 1,
		use_virtual_host      => 1,
	);
}

sub s3_api_with_signature_2 {
	s3_api (
		@_,
		aws_access_key_id     => 'AKIDEXAMPLE',
		aws_secret_access_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
		authorization_method  => 'Net::Amazon::S3::Signature::V2',
		secure                => 1,
		use_virtual_host      => 1,
	);
}

sub expect_net_amazon_s3_feature {
	my ($title, %params) = @_;

	my $s3 = delete $params{with_s3};
	my $feature = delete $params{feature};
	my $expectation = "expect_$feature";

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	subtest $title => sub {
		plan tests => 2;

		if (my $code = Shared::Examples::Net::Amazon::S3::API->can ($expectation)) {
			$code->( "using S3 API" => (
				with_s3 => $s3,
				%params
			));
		} else {
			fail "Net::Amazon::S3 feature expectation $expectation not found";
		}

		if (my $code = Shared::Examples::Net::Amazon::S3::Client->can ($expectation)) {
			$code->( "using S3 Client" => (
				with_client => Net::Amazon::S3::Client->new (s3 => $s3),
				%params
			));
		} else {
			fail "Net::Amazon::S3::Client feature expectation $expectation not found";
		}
	};
}

sub _operation_parameters {
	my ($params, @names) = @_;
	my $map = {};
	$map = shift @names if Ref::Util::is_plain_hashref ($names[0]);

	return
		map +( ($map->{$_} || $_) => $params->{"with_$_"} ),
		grep exists $params->{"with_$_"},
		@names
		;
}

sub _with_keys {
	map "with_$_", @_;
}

sub _keys_operation () {
	return (
		qw[ -shared_examples ],
		qw[ -method ],
		qw[ with_s3 ],
		qw[ with_client ],
		qw[ shared_examples ],
		qw[ with_response_code ],
		qw[ with_response_data ],
		qw[ with_response_headers ],
		qw[ with_response_header_content_type ],
		qw[ with_response_header_content_length ],
		qw[ expect_s3_err ],
		qw[ expect_s3_errstr ],
		qw[ expect_data ],
		qw[ expect_request ],
		qw[ expect_request_content ],
		qw[ expect_request_headers ],
		qw[ throws ],
	);
}

sub _expect_request {
	my ($request, $expect, $title) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my ($method, $uri) = %$expect;
	cmp_deeply
		$request,
		all (
			methods (method => $method),
			methods (uri => methods (as_string => $uri)),
		),
		$title || 'expect request'
		;
}

sub _expect_request_content {
	my ($request, $expected, $title) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my $got = Shared::Examples::Net::Amazon::S3::Request::_canonical_xml ($request->content);
	$expected = Shared::Examples::Net::Amazon::S3::Request::_canonical_xml ($expected);

	cmp_deeply $got, $expected, $title || "expect request content";
}

sub _expect_request_headers {
	my ($request, $expected, $title) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my %got = map +($_ => scalar $request->header ($_)), keys %$expected;

	cmp_deeply
		\ %got,
		$expected,
		$title || "expect request headers"
		;
}

sub _expect_s3_err {
	my ($got, $expected, $title) = @_;

	SKIP: {
		skip "Net::Amazon::S3->err test irrelevant for Client", 1
			if eq_deeply $got, obj_isa ('Net::Amazon::S3::Client');

		cmp_deeply $got, methods (err => $expected), $title || 'expect S3->err';
	}
}

sub _expect_s3_errstr {
	my ($got, $expected, $title) = @_;

	SKIP: {
		skip "Net::Amazon::S3->errstr test irrelevant for Client", 1
			if eq_deeply $got, obj_isa ('Net::Amazon::S3::Client');

		cmp_deeply $got, methods (errstr => $expected), $title || 'expect S3->errstr';
	}
}

sub _expect_operation {
	my ($title, %params) = @_;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	my $class = delete $params{-shared_examples};
	my $operation = delete $params{-operation};

	my $api = $class->_default_with_api (\%params);
	$class->_mock_http_response ($api, %params, into => \ (my $request));

	if (my $code = $class->can ($operation)) {
		subtest $title => sub {
			plan tests => 1
				+ int (!! exists $params{expect_request})
				+ int (!! exists $params{expect_request_content})
				+ int (!! exists $params{expect_request_headers})
				+ int (!! exists $params{expect_s3_err})
				+ int (!! exists $params{expect_s3_errstr})
				;

			my $got;
			my $lives = eval { $got = $api->$code (%params); 1 };
			my $error = $@;

			if ($lives) {
				exists $params{throws}
					? fail "operation expected to throw but lives"
					: cmp_deeply $got, $params{expect_data}, "expect operation return data"
					;
			}
			else {
				$params{throws} = re $params{throws}
					if is_regexpref $params{throws};
				$params{throws} = obj_isa $params{throws}
					if defined $params{throws} && ! ref $params{throws};

				defined $params{throws}
					? cmp_deeply $error, $params{throws}, "it should throw"
					: do { fail "operation expected to live but died" ; diag $error }
					;
			}

			_expect_request $request, $params{expect_request}
				if exists $params{expect_request};
			_expect_request_content $request, $params{expect_request_content}
				if exists $params{expect_request_content};
			_expect_request_headers ($request, $params{expect_request_headers})
				if exists $params{expect_request_headers};

			_expect_s3_err $api, $params{expect_s3_err}
				if exists $params{expect_s3_err};
			_expect_s3_errstr $api, $params{expect_s3_errstr}
				if exists $params{expect_s3_errstr};
		};
	} else {
		fail $title or diag "Operation ${class}::$operation not found";
	}
}

sub _generate_operation_expectation {
	my ($name, @parameters) = @_;

	my @on = (
		('bucket') x!! ($name =~ m/^ ( bucket | object )/x),
		('key')    x!! ($name =~ m/^ ( object )/x),
	);

	my $on = "qw[ ${ \ join ' ', @on } ]";

	eval <<"OPERATION_DECLARATION";
		sub parameters_$name {
			qw[ ${ \ join ' ', @parameters } ]
		}

		sub expect_operation_$name {
			my (\$title, \%params) = \@_;
			local \$Test::Builder::Level = \$Test::Builder::Level + 1;
			Hash::Util::lock_keys \%params, _with_keys ($on, parameters_$name), _keys_operation;
			_expect_operation \$title, \%params, -operation => 'operation_$name';
		}
OPERATION_DECLARATION
}

_generate_operation_expectation list_all_my_buckets =>
	;

_generate_operation_expectation bucket_acl_get =>
	;

_generate_operation_expectation bucket_acl_set =>
	qw[ acl ],
	qw[ acl_xml ],
	qw[ acl_short ],
	;

_generate_operation_expectation bucket_create =>
	qw[ acl ],
	qw[ acl_short ],
	qw[ region ],
	;

_generate_operation_expectation bucket_delete =>
	;

_generate_operation_expectation bucket_objects_list =>
	qw[ delimiter ],
	qw[ max_keys ],
	qw[ marker ],
	qw[ prefix ],
	;

_generate_operation_expectation bucket_objects_delete =>
	qw[ keys ],
	;

_generate_operation_expectation object_acl_get =>
	;

_generate_operation_expectation object_acl_set =>
	qw[ acl ],
	qw[ acl_xml ],
	qw[ acl_short ],
	;

_generate_operation_expectation object_create =>
	qw[ headers ],
	qw[ value ],
	qw[ cache_control  ],
	qw[ content_disposition  ],
	qw[ content_encoding  ],
	qw[ content_type  ],
	qw[ encryption ],
	qw[ expires ],
	qw[ storage_class  ],
	qw[ user_metadata ],
	qw[ acl ],
	qw[ acl_short ],
	;

_generate_operation_expectation object_delete =>
	;

_generate_operation_expectation object_fetch =>
	qw[ range ],
	;

_generate_operation_expectation object_head =>
	;

_generate_operation_expectation bucket_tags_add =>
	qw[ tags ],
	;

_generate_operation_expectation object_tags_add =>
	qw[ tags ],
	qw[ version_id ],
	;

_generate_operation_expectation bucket_tags_delete =>
	;

_generate_operation_expectation object_tags_delete =>
	qw[ version_id ],
	;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3 - used for testing and as example

=head1 VERSION

version 0.99

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
