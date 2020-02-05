package Shared::Examples::Net::Amazon::S3;
# ABSTRACT: used for testing and as example
$Shared::Examples::Net::Amazon::S3::VERSION = '0.88';
use strict;
use warnings;

use parent qw[ Exporter::Tiny ];

use Hash::Util;
use Ref::Util (
    qw[ is_regexpref ],
);

use Test::Deep;
use Test::More;

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
);

sub s3_api_with_signature_4 {
    Net::Amazon::S3->new (
        @_,
        aws_access_key_id     => 'AKIDEXAMPLE',
        aws_secret_access_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
        authorization_method  => 'Net::Amazon::S3::Signature::V4',
        secure                => 1,
        use_virtual_host      => 1,
    );
}

sub s3_api_with_signature_2 {
    Net::Amazon::S3->new (
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

sub _keys_operation {
    return (
        qw[ -shared_examples ],
        qw[ with_s3 ],
        qw[ with_client ],
        qw[ shared_examples ],
        qw[ with_response_code ],
        qw[ with_response_data ],
        qw[ with_response_headers ],
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
    my $guard = $class->_mock_http_response (%params, into => \ (my $request));

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

sub expect_operation_list_all_my_buckets {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_list_all_my_buckets';
}

sub expect_operation_bucket_acl_get {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_bucket_acl_get';
}

sub expect_operation_bucket_acl_set {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_acl_xml ],
        qw[ with_acl_short ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_bucket_acl_set';
}

sub expect_operation_bucket_create {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_acl ],
        qw[ with_region ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_bucket_create';
}

sub expect_operation_bucket_delete {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_bucket_delete';
}

sub expect_operation_bucket_objects_list {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_delimiter ],
        qw[ with_max_keys ],
        qw[ with_marker ],
        qw[ with_prefix ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_bucket_objects_list';
}

sub expect_operation_bucket_objects_delete {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_keys ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_bucket_objects_delete';
}

sub expect_operation_object_acl_get {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_key ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_object_acl_get';
}

sub expect_operation_object_acl_set {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_key ],
        qw[ with_acl_xml ],
        qw[ with_acl_short ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_object_acl_set';
}

sub expect_operation_object_create {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_headers ],
        qw[ with_key ],
        qw[ with_value ],
        qw[ with_cache_control  ],
        qw[ with_content_disposition  ],
        qw[ with_content_encoding  ],
        qw[ with_content_type  ],
        qw[ with_encryption ],
        qw[ with_expires ],
        qw[ with_storage_class  ],
        qw[ with_user_metadata ],

        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_object_create';
}

sub expect_operation_object_delete {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_key ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_object_delete';
}

sub expect_operation_object_fetch {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_key ],

        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_object_fetch';
}

sub expect_operation_object_head {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    Hash::Util::lock_keys %params,
        qw[ with_bucket ],
        qw[ with_key ],
        _keys_operation,
        ;

    _expect_operation $title, %params, -operation => 'operation_object_head';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3 - used for testing and as example

=head1 VERSION

version 0.88

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
