#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Params::Validate::Strict qw(validate_strict);

# Mock logger for testing logging functionality
{
	package MockLogger;
	sub new { bless {}, shift }
	# sub debug { shift; ::diag('DEBUG: ', join('', @_)) }
	# sub error { shift; ::diag('ERROR: ', join('', @_)); die @_ }
	# sub warn { shift; ::diag('WARN: ', join('', @_)) }

	sub debug { }
	sub error { die @_ }
	sub warn {}
}

# Test unknown parameter with 'ignore' and logger
subtest 'unknown parameter with ignore and logger' => sub {
	my $logger = MockLogger->new;
	my $schema = { known => { type => 'string' } };
	my $input = { known => 'value', unknown => 'value' };

	my $result = validate_strict(
		schema => $schema,
		input => $input,
		unknown_parameter_handler => 'ignore',
		logger => $logger,
	);

	is_deeply $result, { known => 'value' }, 'unknown parameter ignored';
};

# Test coderef type validation
subtest 'coderef validation' => sub {
	my $schema = { callback => { type => 'coderef' } };

	# Valid coderef
	my $input = { callback => sub {} };
	my $result = validate_strict(schema => $schema, input => $input);
	is ref $result->{callback}, 'CODE', 'coderef accepted';

	# Invalid coderef
	$input = { callback => 'not_code' };
	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/must be a coderef/, 'non-coderef rejected';
};

# Test min/max with undefined values
subtest 'min/max with undefined values' => sub {
	my $schema = {
		arr => { type => 'arrayref', min => 1, optional => 1 },
		hash => { type => 'hashref', max => 2, optional => 1 },
		num => { type => 'number', min => 0, optional => 1 },
	};

	my $input = { arr => undef, hash => undef, num => undef };
	my $result = validate_strict(schema => $schema, input => $input);
	is_deeply $result, $input, 'undefined values skipped for optional min/max';
};

# Test matches and nomatch for arrayref
subtest 'matches and nomatch for arrayref' => sub {
	my $schema = {
		matches => { type => 'arrayref', matches => qr/^a/, optional => 1 },
		nomatch => { type => 'arrayref', nomatch => qr/^b/, optional => 1 },
	};

	# Matches failure
	my $input = { matches => ['a', 'b'] };
	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/must match pattern/, 'arrayref matches failure';

	# Nomatch failure
	$input = { nomatch => ['a', 'b'] };
	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/No member of parameter/, 'arrayref nomatch failure';
};

# Test memberof validation failures
subtest 'memberof validation failures' => sub {
	my $schema = {
		num => { type => 'integer', memberof => [1, 2, 3], optional => 1 },
		str => { type => 'string', memberof => ['a', 'b'], optional => 1 },
	};

	# Numeric failure
	my $input = { num => 4 };
	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/must be one of/, 'numeric memberof failure';

	# String failure
	$input = { str => 'c' };
	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/must be one of/, 'string memberof failure';
};

# Test can validation with multiple methods
subtest 'can validation with multiple methods' => sub {
	my $schema = { obj => { type => 'object', can => ['method1', 'method2'] } };

	# Mock object missing methods
	my $broken_obj = bless {}, 'BrokenClass';
	my $input = { obj => $broken_obj };

	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/understands the method/, 'can validation with multiple methods fails';
};

# Test invalid rule types
subtest 'invalid rule types' => sub {
	my $schema = { param => { invalid_rule => 'value' } };
	my $input = { param => 'value' };

	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/Unknown rule/, 'unknown rule rejected';
};

# Test logger usage in _error and _warn
subtest 'logger in _error and _warn' => sub {
	my $logger = MockLogger->new;
	my $schema = { param => { type => 'invalid_type' } };
	my $input = { param => 'value' };

	throws_ok {
		validate_strict(schema => $schema, input => $input, logger => $logger);
	} qr/Unknown type/, 'error logged with logger';
};

# Test args existence but undefined
subtest 'args exists but undefined' => sub {
	my $schema = { param => { type => 'string', 'optional' => 1 } };
	my $result = validate_strict(schema => $schema, args => undef);
	is_deeply $result, {}, 'undefined args becomes empty hash';
};

# Test min greater than max
subtest 'min greater than max' => sub {
	my $schema = { param => { type => 'string', min => 10, max => 5 } };
	my $input = { param => 'value' };

	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/min must be <= max/, 'min > max rejected';
};

# Test invalid regex in matches
subtest 'invalid regex in matches' => sub {
	my $schema = { param => { type => 'string', matches => '(invalid' } };
	my $input = { param => 'value' };

	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/invalid regex/, 'invalid regex rejected';
};

# Test a string is given
subtest 'arg must be a string' => sub {
	my $schema = { param => { type => 'string' } };
	my $input = { param => {} };

	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/must be a string/, 'A hashref is not a string';

	$schema->{'param'}->{'error_message'} = 'Param must only be a string';

	throws_ok {
		validate_strict(schema => $schema, input => $input);
	} qr/must only be a string/, 'Check custom error message';
};

done_testing();
