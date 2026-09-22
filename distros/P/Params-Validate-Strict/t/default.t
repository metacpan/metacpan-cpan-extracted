#!/usr/bin/env perl

# Test default values for optional parameters

use strict;
use warnings;
use Test::Most;
use Params::Validate::Strict qw(validate_strict);

my $schema = {
	username => { type => 'string', optional => 1, 'default' => 'xyzzy' }
};

my $result = validate_strict({ schema => $schema, args => {} });

is_deeply($result, { username => 'xyzzy' }, 'default is honoured when parameter is absent');

my $result2 = validate_strict({ schema => $schema, args => { username => 'alice' } });

is_deeply($result2, { username => 'alice' }, 'supplied value overrides default');

done_testing();
