#!/usr/bin/env perl

# Test that strings don't accept stringrefs

use strict;
use warnings;
use Test::Most;
use Params::Validate::Strict qw(validate_strict);

my $schema = {
	name => { type => 'string', optional => 0 }
};

my $result = validate_strict({ schema => $schema, args => { name => 'v' } });

is_deeply($result, { name => 'v' }, 'string works');

throws_ok { $result = validate_strict(schema => $schema, args => { name => \'n' } ) }
	qr /must be a string/,
	'stringref to a string throws an exception';

done_testing();
