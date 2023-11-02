#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::Role::Request;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Request /;

	sub _path_params { [ qw/ path_param1 path_param2 / ] }
	sub _query_params { [ qw/ query_param1 query_param2 / ] }

	1;
}

throws_ok
	{ Test::Role::Request->new }
	qr/you must override default url value/
;

isa_ok(
	my $Request = Test::Role::Request->new( url => 'idosurehopeidonotexist' ),
	'Test::Role::Request'
);

can_ok $Request, qw/
	get_req_p
	post_req_p
/;

subtest '->_handle_request' => sub {

	$Request
		->_handle_request('post_p')
		->catch( sub {
			my ( $Exception ) = @_;

			is ref $Exception, 'PayProp::API::Public::Client::Exception::Connection';
		} )
		->wait
	;

};

subtest '->_build_url' => sub {

	my $TestRequest = Test::Role::Request->new( url => 'http://example.com/api/agency/v1.1/some-endpoint' );

	subtest 'query params' => sub {

		is
			$TestRequest->_build_url({ not_legit => 1, query_param1 => 'value1', query_param2 => 'value2' }),
			'http://example.com/api/agency/v1.1/some-endpoint?query_param1=value1&query_param2=value2'
		;
	};

	subtest 'path params' => sub {

		is
			$TestRequest->_build_url({
				not_legit => 1,
				query_param1 => 'value',
				path_params => {
					path_param1 => 'path_param_value1',
					path_param2 => 'path_param_value2',
				},
			}),
			'http://example.com/api/agency/v1.1/some-endpoint/path_param_value1/path_param_value2?query_param1=value'
		;
	};

};

done_testing;
