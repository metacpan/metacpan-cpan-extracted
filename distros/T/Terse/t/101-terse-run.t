use Test::Instruction qw/all/;

BEGIN {
        *CORE::GLOBAL::time = sub { 1531922097; }; 
}

use Terse;
{
	package App::Test;
	
	use base 'Terse';

	sub auth {
		return 1;
	}

	sub test {
		$_[1]->response->okay = 'abc';
	}

	sub unauth {
		$_[1]->response->authenticated = \0;
	}

	1;
}

instructions(
        name => 'Success Test',
        build => {
                class => 'Terse',
        	new => 'run',
		args => [
			application => 'App::Test',
			plack_env => {
				'plack.request.merged' => {
					req => 'test',
				},
				'plack.cookie.parsed' => {
					sid => 'd14b87d8df67517f42ea35ea9630b545fb99be174e328de50ce789c32bf668b3',
				},
				HTTP_COOKIE => 1,
				'plack.cookie.string' => 1,
			}
		],
		args_list => 1,
	},
	run => [{
		test => "array",
		expected => [200,
			[
				'Content-Type',
				'application/json',
				'Set-Cookie',
				'sid=d14b87d8df67517f42ea35ea9630b545fb99be174e328de50ce789c32bf668b3; path=http:///; expires=Wed, 18-Jul-2018 13:54:57 GMT; secure'
			],
			[
				'{"authenticated":true,"error":false,"errors":[],"okay":"abc","status_code":200}'
			]
		]
	}]
);

instructions(
        name => 'Invalid Req',
        build => {
                class => 'Terse',
        	new => 'run',
		args => [
			application => 'App::Test',
			plack_env => {
				'plack.request.merged' => {
					req => 'testing',
				},
				'plack.cookie.parsed' => {
					sid => 'd14b87d8df67517f42ea35ea9630b545fb99be174e328de50ce789c32bf668b3',
				},
				HTTP_COOKIE => 1,
				'plack.cookie.string' => 1,
			}
		],
		args_list => 1,
	},
	run => [{
		test => "array",
		expected => [400,
			[
				'Content-Type',
				'application/json',
			],
			[
				'{"authenticated":true,"error":true,"errors":["Invalid request - testing"],"status_code":400}'
			]
		]
	}]
);

instructions(
        name => 'Unauthenticated',
        build => {
                class => 'Terse',
        	new => 'run',
		args => [
			application => 'App::Test',
			plack_env => {
				'plack.request.merged' => {
					req => 'unauth',
				},
				'plack.cookie.parsed' => {
					sid => 'd14b87d8df67517f42ea35ea9630b545fb99be174e328de50ce789c32bf668b3',
				},
				HTTP_COOKIE => 1,
				'plack.cookie.string' => 1,
			}
		],
		args_list => 1,
	},
	run => [{
		test => "array",
		expected => [400,
			[
				'Content-Type',
				'application/json',
			],
			[
				'{"authenticated":false,"error":true,"errors":["Unauthenticated during the request"],"status_code":400}'
			]
		]
	}]
);


finish();
