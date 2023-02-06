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
					test => 'ok',
					meth => 'logInfo',
					args_list => 1,
					args => [ 'Testing' ]
				},
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
			_application => 'Hospital2'
		]
	},
	run => [
		{
			test => 'ok',
			instructions => [
				{
					test => 'ok',
					meth => 'logInfo',
					args_list => 1,
					args => [ 'Testing' ]
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
					test => 'ok',
					meth => 'logInfo',
					args_list => 1,
					args => [ 'Testing' ],
				},
			]
		}
	]
);

instruction(
	test => 'hash',
	instance => $message,
	expected => {
		message => 'Testing',
		other => 'okay'
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
				info => sub {
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
					test => 'ok',
					meth => 'logInfo',
					args_list => 1,
					args => [ 'Testing Different' ],
				},
			]
		}
	]
);

instruction(
	test => 'hash',
	instance => $message,
	expected => {
		message => 'Testing Different',
		other => 'okay'
	}
);

finish(26);
