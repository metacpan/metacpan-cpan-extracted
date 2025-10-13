#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Needs 'Params::Get';

BEGIN { use_ok('Params::Validate::Strict') };

sub where_am_i
{
	my $params = Params::Validate::Strict::validate_strict({
		args => Params::Get::get_params(undef, @_),
		schema => {
			'latitude' => {
				type => 'float',
				min => -180,
				max => 180
			}, 'longitude' => {
				type => 'float',
				min => -180,
				max => 180
			}
		}
	});
	return 'You are at ' . $params->{'latitude'} . ', ' . $params->{'longitude'};
}

cmp_ok(where_am_i(latitude => 10, longitude => 100), 'eq', 'You are at 10, 100');

done_testing();
