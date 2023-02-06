use Test::Instruction qw/all/;
use Terse;
use lib 't/lib';
use Hospital;
use Hospital2;

instructions(
	name => 'no application and no logger',
	build => {
		class => 'Terse',
		args => ()
	},
	run => [
		{
			test => 'ok',
			instructions => [
				{
					test => 'ref_key_ref',
					meth => 'logError',
					key => 'errors',
					args_list => 1,
					args => [ 'Test Error', 500 ],
					expected => [ 'Test Error' ],
				},
				{
					test => 'ref_key_ref',
					key => 'status_code',
					expected => 500
				}
			]
		}
	]
);

instructions(
	name => 'application but no logger',
	build => {
		class => 'Terse',
		args_list => 1,
		args => [
			_application => 'Hospital'
		]
	},
	run => [
		{
			test => 'ok',
			instructions => [
				{
					test => 'ref_key_ref',
					meth => 'logError',
					key => 'response',
					args_list => 1,
					args => [ 'Test Error', 500 ],
					expected => {
						error => \1,
						errors => [ 'Test Error' ],
						status_code => 500
					}
				},
			]
		}
	]
);

my $message;

instructions(
	name => 'application with CODE block logger',
	build => {
		class => 'Terse',
		args_list => 1,
		args => [
			_application => 'Hospital2',
			_logger => sub {
				my ($type, $msg) = @_;
				$message = $msg;
			}
		]
	},
	run => [
		{
			test => 'ok',
			instructions => [
				{
					test => 'ref_key_ref',
					meth => 'logError',
					key => 'response',
					args_list => 1,
					args => [ { message => 'Test Error' }, 500, 1 ],
					expected => {
						error => \1,
						errors => [ { message => 'Test Error', test => 'okay' } ],
						status_code => 500,
						no_response => 1
					}
				},
			]
		}
	]
);

instruction(
	test => 'hash',
	instance => $message,
	expected => {
		message => 'Test Error',
		test => 'okay'
	}
);

instructions(
	name => 'application with object logger',
	build => {
		class => 'Terse',
		args_list => 1,
		args => [
			_application => 'Hospital2',
			_logger => Terse->new(
				error => sub {
					my ($self, $msg) = @_;
					$message = $msg;
				}
			)
		]
	},
	run => [
		{
			test => 'ok',
			instructions => [
				{
					test => 'ref_key_ref',
					meth => 'logError',
					key => 'response',
					args_list => 1,
					args => [ { message => 'Test Error' }, 500, 1 ],
					expected => {
						error => \1,
						errors => [ { message => 'Test Error', test => 'okay' } ],
						status_code => 500,
						no_response => 1
					}
				},
			]
		}
	]
);

instruction(
	test => 'hash',
	instance => $message,
	expected => {
		message => 'Test Error',
		test => 'okay'
	}
);

finish(27);
