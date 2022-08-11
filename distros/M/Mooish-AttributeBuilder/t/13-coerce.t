use v5.10;
use strict;
use warnings;

use Test::More;
use Mooish::AttributeBuilder;

{

	package CoerceTest;

	sub new
	{
		return bless {}, shift;
	}
}

subtest 'testing coerce' => sub {
	my $obj = CoerceTest->new;
	my ($name, %params) = field 'param', coerce => $obj;

	is $params{isa}, $obj, 'isa ok';
	is $params{coerce}, 1, 'coerce ok';
};

done_testing;

