#!perl -T

use strict;
use warnings;

use String::InterpolatedVariables;
use Test::Deep;
use Test::FailWarnings -allow_deps => 1;
use Test::More;


my $tests =
[
	{
		string   => 'A test $variable string',
		expected => [ '$variable' ],
	},
	{
		string   => "A test string\n with \$variable",
		expected => [ '$variable' ],
	},
	{
		string   => 'A test $variable $variable string',
		expected => [ '$variable' ],
	},
	{
		string   => 'A test $variable_long string',
		expected => [ '$variable_long' ],
	},
	{
		string   => 'A test ${variable_long} string',
		expected => [ '${variable_long}' ],
	},
	{
		string   => 'A test $test->{value} string',
		expected => [ '$test->{value}' ],
	},
	{
		string   => 'A test $test->{value}->[1]->{"key"} string',
		expected => [ '$test->{value}->[1]->{"key"}' ],
	},
	{
		string   => 'A test $$test{value}[1]{"key"} string',
		expected => [ '$$test{value}[1]{"key"}' ],
	},
	{
		string   => 'A test $$test{value}[1]{"key"} ${variable_long} $test->{value}->[1]->{"key"} string',
		expected => [ '$$test{value}[1]{"key"}', '${variable_long}', '$test->{value}->[1]->{"key"}' ],
	},
];

plan( tests => scalar( @$tests ) );

foreach my $test ( @$tests )
{
	my $extracted = String::InterpolatedVariables::extract( $test->{'string'} );
	my $name = "Extract variables from >$test->{'string'}<.";
	$name =~ s/\n/\\n/g;
	is_deeply(
		$extracted,
		$test->{'expected'},
		$name,
	) || diag( explain( $extracted ) );
}
