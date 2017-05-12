#!perl


use Test::Spec;
use MooseX::ErrorHandling;
use Moose::Util qw(throw_exception);
use Test::Deep;

describe 'MooseX::ErrorHandling' => sub {
	it 'exports a insteadDo keyword' => sub {
		my $cb = insteadDo {
			pass();
		};

		$cb->();
	};

	it 'exports an whenMooseThrows keyword' => sub {
		ok(main->can('whenMooseThrows'));
	};

	it 'wraps a moose exception' => sub {
		my $error = "WAS_WRAPPED\n";

		whenMooseThrows BothBuilderAndDefaultAreNotAllowed => insteadDo {
			die $error;
		};

		eval {
			throw_exception('BothBuilderAndDefaultAreNotAllowed', params => { foo => 1}, class => 'main');
		};

		my $e = $@;
		cmp_deeply($e, $error);
	};

	it 'puts the original exception in $_' => sub {
		my $was_called;
		whenMooseThrows Legacy => insteadDo {
			$was_called++;
			cmp_deeply($_,
				all(
					isa('Moose::Exception::Legacy'),
					methods(message => 'epcot'),
				)
			);
		};

		eval {
			throw_exception('Legacy', message => 'epcot');
		};

		ok($was_called);
	};
};

runtests;
