use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('Params::Get', qw(get_params)) }

# Dummy class for blessed object tests
{
	package Dummy;
	use overload '""' => sub { 'dummy' };
	sub new { bless {}, shift }
}

my $blessed_obj = new_ok('Dummy');
my $scalar_ref = \'val';
my $code_ref = sub { 'hi' };

my @tests = (
	{
		name => 'Single hashref',
		input => [ { foo => 'bar' } ],
		expected => { foo => 'bar' },
	}, {
		name => 'Default + scalar',
		input => [ 'country', 'US' ],
		expected => { country => 'US' },
	}, {
		name => 'Default + arrayref',
		input => [ 'tags', ['perl', 'VWF'] ],
		expected => { tags => ['perl', 'VWF'] },
	}, {
		name => 'Default + scalar ref',
		input => [ 'key', $scalar_ref ],
		expected => { key => 'val' },
	}, {
		name => 'Default + empty arrayref',
		input => [ 'list', [] ],
		expected => { list => [] },
		dies => 1,
	}, {
		name => 'Default + code ref',
		input => [ 'run', $code_ref ],
		expected => { run => $code_ref },
	}, {
		name => 'Default + blessed object',
		input => [ 'thing', $blessed_obj ],
		expected => { thing => $blessed_obj },
	}, {
		name => 'Special form arrayref matching default',
		input => [ 'country', ['country', 'US'] ],
		expected => { country => 'US' },
	}, {
		name => 'Even args as key-value pairs',
		input => [ undef, 'k1', 'v1', 'k2', 'v2' ],
		expected => { k1 => 'v1', k2 => 'v2' },
	},
);

foreach my $test (@tests) {
	if($test->{'dies'}) {
		dies_ok(sub { get_params(@{$test->{'input'}}) }, $test->{'name'});
	} else {
		lives_ok(sub { get_params(@{$test->{'input'}}) });
		is_deeply(get_params(@{$test->{input}}), $test->{expected}, $test->{name});
	}
}

done_testing();
