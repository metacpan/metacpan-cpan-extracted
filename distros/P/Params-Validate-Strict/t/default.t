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

is_deeply($result, { username => 'xyzzy' }, 'default is honoured');

done_testing();
