use Test::More tests => 30;
use strict;
$^W = 1;

my $class = 'Return::Value';

use Return::Value;

{
	my $message = "I've got a bad feelin' about this.";
	my $value = failure $message;

	isa_ok($value, $class, "failure value");

	ok(not($value),          "failure value is false");
	ok($value == 0,          "failure value is 0");
	ok($value eq $message,   "failure value has a bad feelin'");
	is($value->errno, 1,     "failure value errno is default (1)");
}

{
	my $message = "I've got a bad feelin' about this.";
	my $value = failure $message, errno => 501, data => { cause => 'sunspots' };

	isa_ok($value, $class, "failure value");

	ok(not($value),          "failure value is false");
	ok($value == 0,          "failure value is 0");
	ok($value eq $message,   "failure value has a bad feelin'");
	is($value->errno, 501,   "failure value has 501 errno");

	is(ref $value->data,   'HASH',     "failure value includes hashref");
	is($value->{cause},    'sunspots', "failure value derefs correctly");
}

{
	my $message = "I've got a bad feelin' about this.";
	my $value = failure $message, errno => 501, data => [ cause => 'sunspots' ];

	isa_ok($value, $class, "failure value");

	ok(not($value),          "failure value is false");
	ok($value == 0,          "failure value is 0");
	ok($value eq $message,   "failure value has a bad feelin'");
	is($value->errno, 501,   "failure value has 501 errno");

	is(ref $value->data,   'ARRAY',    "failure value includes hashref");
	is($value->[1],        'sunspots', "failure value derefs correctly");
}

{
	my $value = failure errno => 501, data => [ cause => 'sunspots' ];

	isa_ok($value, $class, "failure value");

	ok(not($value),          "failure value is false");
	ok($value == 0,          "failure value is 0");
	ok($value eq 'failure',  "failure value has default stringification");
	is($value->errno, 501,   "failure value has 501 errno");

	is(ref $value->data,   'ARRAY',    "failure value includes hashref");
	is($value->[1],        'sunspots', "failure value derefs correctly");
}

{
	my $value = failure;

	isa_ok($value, $class, "failure value");

	ok(not($value),          "failure value is true");
	ok($value == 0,          "failure value is 0");
	ok($value eq 'failure',  "failure has default stringification");
}
