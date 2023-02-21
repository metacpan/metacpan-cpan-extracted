use Test::Instruction qw/all/;
use Terse;

instructions(
        name => 'fail graft',
        build => {
                class => 'Terse',
        	new => 'new',
	},
	run => [{
		test => 'false',
		meth => 'graft',
		args_list => 1,
		args => [ 'data', '{{"a"}:{"b"}}' ],
	}, {
		test => 'scalar',
		meth => 'data',
		expected => ''
	}]
);

instructions(
        name => 'graft hash',
        build => {
                class => 'Terse',
        	new => 'new',
	},
	run => [{
		test => 'ok',
		meth => 'graft',
		args_list => 1,
		args => [ 'data', '{"a":"b"}' ],
		instructions => [{
			test => 'hash',
			expected => {
				a => 'b'
			}
		}]
	}, {
		test => 'hash',
		meth => 'data',
		expected => {
			a => 'b'
		}
	}]
);

instructions(
        name => 'graft array',
        build => {
                class => 'Terse',
        	new => 'new',
	},
	run => [{
		test => 'ok',
		meth => 'graft',
		args_list => 1,
		args => [ 'data', '["a", "b"]' ],
		instructions => [{
			test => 'array',
			expected => [
				'a', 'b'
			]
		}]
	}, {
		test => 'array',
		meth => 'data',
		expected => [
			'a', 'b'
		]
	}]
);

instructions(
        name => 'graft string',
        build => {
                class => 'Terse',
        	new => 'new',
	},
	run => [{
		test => 'ok',
		meth => 'graft',
		args_list => 1,
		args => [ 'data', 'a' ],
		instructions => [{
			test => 'scalar',
			expected => 'a'
		}]
	}, {
		test => 'scalar',
		meth => 'data',
		expected => 'a'
	}]
);

finish(25);
