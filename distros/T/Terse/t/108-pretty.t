use Test::Instruction qw/all/;
use Terse;

instructions(
        name => 'pretty',
        build => {
                class => 'Terse',
        	new => 'new',
	},
	run => [{
		test => 'ok',
		meth => 'pretty',
		instructions => [{
			test => 'true',
		}]
	}]
);

finish(6);
