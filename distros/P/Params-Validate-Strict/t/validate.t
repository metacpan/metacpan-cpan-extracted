#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 5;
use Params::Validate::Strict qw(validate_strict);

# Test validation coderef
sub test_validation {
	my $count;
	my $schema = {
		user => {
			type => 'string',
			validate => sub {
				$count++;
				if($_[0]->{'password'} eq 'bar') {
					return undef;
				}
				return 'Invalid password, try again';
			}
		}, password => {
			type => 'string'
		}
	};

	my $valid_input = {
		user => 'Fred Bloggs',
		password => 'bar'
	};

	my $invalid_password = {
		user => 'Fred Bloggs',
		password => 'xxx'
	};

	# Test valid input
	my $result;
	lives_ok {
		$result = validate_strict(schema => $schema, input => $valid_input);
	} 'Valid input should work';

	is(ref $result, 'HASH', "Result should be a hashref");
	cmp_ok($result->{user}, 'eq', 'Fred Bloggs', 'User should be correct');

	# Test invalid zip code
	throws_ok {
		validate_strict(schema => $schema, input => $invalid_password);
	} qr/Invalid password, try again/, 'Password failure should give an error';

	cmp_ok($count, '==', 2, 'Validation routine was called twice');
}

# Run the tests
test_validation();

done_testing();
