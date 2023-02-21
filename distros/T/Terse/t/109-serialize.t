use Test::Instruction qw/all/;
use Terse;


instructions(
        name => 'serialize hash',
        build => {
                class => 'Terse',
        	new => 'new',
		args_list => 1,
		args => [ a => sub { } ],	
	},
	run => [{
		test => 'like',
		meth => 'serialize',
		expected => 'encountered CODE' 	
	}]
);



instructions(
        name => 'serialize hash',
        build => {
                class => 'Terse',
        	new => 'new',
		args_list => 1,
		args => [ a => "b" ],	
	},
	run => [{
		test => 'ok',
		meth => 'serialize',	
		instructions => [{
			test => 'scalar',
			expected => '{"a":"b"}'
		}]
	}]
);

instructions(
        name => 'serialize array',
        build => {
                class => 'Terse',
        	new => 'new',
	},
	run => [{
		test => 'ok',
		meth => 'graft',
		args_list => 1,
		args => [ 'data', '["a","b"]' ],
		instructions => [{
			test => 'array',
			expected => ["a", "b"]
		}, { 
			test => 'scalar',
			meth => 'serialize',
			expected => '["a","b"]'
		}]
	}]
);

finish(16);
