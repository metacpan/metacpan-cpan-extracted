#!perl

use strict;
use warnings;

use Test::Most;


{
	package Test::Role::Request;

	use Mouse;
	with qw/ PayProp::API::Public::Client::Role::Request /;

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
	put_req_p
	get_req_p
	post_req_p
	delete_req_p
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

		my $url = $TestRequest->_build_url({ query_param1 => 'value1', query_param2 => 'value2' });

		like $url, qr{http://example.com/api/agency/v1.1/some-endpoint}, 'base url';
		like $url, qr{query_param1=value1}, 'query_param1';
		like $url, qr{query_param2=value2}, 'query_param2';

	};

	subtest 'path params' => sub {

		$TestRequest->ordered_path_params([qw/ fragment1 fragment2 fragment3 /]);

		is
			$TestRequest
				->_build_url( undef, {
					fragment1 => 'replaced_fragment_1',
					fragment2 => 'replaced_fragment_2',
					fragment3 => 'replaced_fragment_3',
				}),
			'http://example.com/api/agency/v1.1/some-endpoint/replaced_fragment_1/replaced_fragment_2/replaced_fragment_3'
		;

	};

};

done_testing;
