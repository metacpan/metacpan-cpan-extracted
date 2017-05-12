use Test::More;

{
	package CalculatorAPI;
	use MooseX::Interface;

	requires 'add';
	test_case { $_->add(8, 2) == 10 } 'add-1';

	requires 'subtract';
	test_case { $_->subtract(8, 2) == 6 } 'subtract-1';

	requires 'multiply';
	test_case { $_->multiply(8, 2) == 16 } 'multiply-1';

	requires 'divide';
	test_case { $_->divide(8, 2) == 4 } 'divide-1';

	one;
}

{
	package Calculator;
	use Moose;
	with 'CalculatorAPI';
	sub add      { $_[1] + $_[2] }
	sub subtract { $_[1] - $_[2] }
	sub multiply { $_[1] * $_[2] }
	sub divide   { $_[1] / $_[2] }
}

{
	package BrokenCalculator;
	use Moose;
	with 'CalculatorAPI';
	sub add      { $_[1] - $_[2] }
	sub subtract { $_[1] + $_[2] }
	sub multiply { $_[1] * $_[2] }
	sub divide   { $_[1] / $_[2] }
}

ok(
	CalculatorAPI->meta->test_implementation(Calculator->new)
);

ok(
	not CalculatorAPI->meta->test_implementation(BrokenCalculator->new)
);

{
	package ScientificCalculatorAPI;	
	use MooseX::Interface;
	extends 'CalculatorAPI';	
	requires 'pow';
	test_case { $_->pow(8, 2) == 64 } 'pow-1';
	one;
}

{
	package ScientificCalculator;
	use Moose;
	extends 'Calculator';
	with 'ScientificCalculatorAPI';
	sub pow      { $_[1] ** $_[2] }
}

{
	package UnscientificCalculator;
	use Moose;
	extends 'Calculator';
	with 'ScientificCalculatorAPI';
	sub pow      { $_[1] ** $_[2] }
	sub multiply { $_[1] + $_[2] }  # b0rked
}

{
	package LudditeCalculator;
	use Moose;
	extends 'Calculator';
	with 'ScientificCalculatorAPI';
	sub pow      { $_[1] - $_[2] } # b0rked
	sub multiply { $_[1] * $_[2] }
}

ok(
	CalculatorAPI->meta->test_implementation(ScientificCalculator->new)
);

ok(
	ScientificCalculatorAPI->meta->test_implementation(ScientificCalculator->new)
);

ok(
	not ScientificCalculatorAPI->meta->test_implementation(UnscientificCalculator->new)
);

ok(
	CalculatorAPI->meta->test_implementation(LudditeCalculator->new)
);

ok(
	not ScientificCalculatorAPI->meta->test_implementation(LudditeCalculator->new)
);

my $r = ScientificCalculatorAPI->meta->test_implementation(LudditeCalculator->new);
cmp_ok($r, '==', 1);
cmp_ok($r, 'eq', 'not ok');
is($r->failed->[0]->name, 'pow-1');
is_deeply(
	[ sort map { $_->name } @{$r->passed} ],
	[ qw/ add-1 divide-1 multiply-1 subtract-1 / ],
);

done_testing();