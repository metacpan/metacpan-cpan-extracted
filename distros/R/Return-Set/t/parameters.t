use strict;
use warnings;

use Test::Most;
use Return::Set qw(set_return);

note('Testing positional arguments');
is(set_return(5), 5, 'Returns value without schema (positional)');
is(set_return(42, { type => 'integer' }), 42, 'Validates scalar (positional)');

note('Testing named parameters');
is(set_return({ value => 7 }), 7, 'Returns value without schema (named)');
is(set_return({ value => 99, schema => { type => 'integer' } }), 99, 'Validates scalar (named)');

throws_ok {
	set_return({ value => ['a'], schema => { type => 'integer' } });
} qr/Validation failed/, 'Fails validation for non-scalar (named)';

# Basic usage: return scalar without schema
is set_return("hello"), "hello", "Basic scalar return works";

# Return with schema validation
is set_return(123, { type => 'integer' }), 123, "Integer validated successfully";

# Validation failure
throws_ok { set_return("not-an-int", { type => 'integer' }) }
    qr/Validation failed/,
    "Validation fails with non-integer input";

# Params::Get-style arguments (hashref with output/schema)
my $val = set_return(
    { output => 456, schema => { type => 'integer' } }
);
is $val, 456, "Params::Get style arguments work";

# Params::Get-style with 'value' instead of 'output'
my $val2 = set_return(
    { value => "string", schema => { type => 'string' } }
);
is $val2, "string", "Params::Get with 'value' key works";

# No arguments
throws_ok { set_return() }
    qr/Usage:.+set_return/,
    "Dies with usage message if no arguments passed";

# Single non-ref argument
is set_return("only"), "only", "Single non-ref arg returned as-is";

# Single ref argument
cmp_ok(set_return({ output => "bar" }), 'eq', 'bar', 'Single ref argument');

done_testing();
