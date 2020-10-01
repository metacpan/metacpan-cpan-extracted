#!perl

use strict;
use warnings;

use FindBin;
use lib $FindBin::Bin;

BEGIN { require 'test-helper-common.pl' }

use Shared::Examples::Net::Amazon::S3 qw[ with_response_fixture ];

use HTTP::Response;
use HTTP::Status;

sub expect_response_class {
    my ($response_class) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    return use_ok $response_class;
}

sub expect_response_instance {
    my (%params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $class   = delete $params{response_class};
    my $content = delete $params{with_response_data};
    my $code    = delete $params{with_response_code};
    my $message = delete $params{with_response_message} // HTTP::Status::status_message ($code);
    my $header  = delete $params{with_response_header} // {};

    for (grep m/^with_response_header_/, keys %params) {
        m/^with_response_header_(.*)/;
        $header->{$1} //= $params{$_};
    }

    $header->{content_length} //= length $content
        if $content && length $content;

    my $http_response = HTTP::Response->new (
        $code,
        $message,
        [ %$header ],
        $content
    );

    $http_response->request ($params{with_origin_request})
        if $params{with_origin_request};

    return $class->new (
        http_response => $http_response
    );
}

sub behaves_like_s3_response {
    my ($title, %params) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $title => sub {
        plan tests => 1 + scalar grep exists $params{$_},
            qw[ expect_success ],
            qw[ expect_error ],
            qw[ expect_redirect ],
            qw[ expect_internal_response ],
            qw[ expect_xml_content ],
            qw[ expect_response ],
            qw[ expect_response_data ],
            qw[ expect_error_code ],
            qw[ expect_error_message ],
            qw[ expect_error_resource ],
            qw[ expect_error_request_id ],
            ;

        expect_response_class $params{response_class};
        my $response = expect_response_instance %params;

		cmp_deeply "expect response is success" => (
			if     => exists $params{expect_success},
			got    => sub { scalar $response->is_success },
			expect => sub { bool ($params{expect_success}) },
		);

		cmp_deeply "expect response is error" => (
			if     => exists $params{expect_error},
			got    => sub { scalar $response->is_error },
			expect => sub { bool ($params{expect_error}) },
		);

		cmp_deeply "expect response is redirect" => (
			if     => exists $params{expect_redirect},
			got    => sub { scalar $response->is_redirect },
			expect => sub { bool ($params{expect_redirect}) },
		);

		cmp_deeply "expect internal response" => (
			if     => exists $params{expect_internal_response},
			got    => sub { scalar $response->is_internal_response },
			expect => sub { bool ($params{expect_internal_response}) },
		);

		cmp_deeply "expect response xml content" => (
			if     => exists $params{expect_xml_content},
			got    => sub { scalar $response->is_xml_content },
			expect => sub { bool ($params{expect_xml_content}) },
		);

        cmp_deeply "expect response error code" => (
            if     => exists $params{expect_error_code},
			got    => sub { $response->error_code },
			expect => $params{expect_error_code},
		);

        cmp_deeply "expect response error message" => (
            if     => exists $params{expect_error_message},
			got    => sub { $response->error_message },
			expect => $params{expect_error_message},
		);

        cmp_deeply "expect response error resource" => (
            if     => exists $params{expect_error_resource},
			got    => sub { $response->error_resource },
			expect => $params{expect_error_resource},
		);

        cmp_deeply "expect response error request id" => (
            if     => exists $params{expect_error_request_id},
			got    => sub { $response->error_request_id },
			expect => $params{expect_error_request_id},
		);

        cmp_deeply "expect response data" => (
            if     => exists $params{expect_response_data},
			got    => sub { $response->data },
			expect => sub { bool ($params{expect_response_data}) },
		);

        cmp_deeply "expect response" => (
            if     => exists $params{expect_response},
			got    => $response,
			expect => $params{expect_response},
		);

		done_testing;
    };
}

1;
