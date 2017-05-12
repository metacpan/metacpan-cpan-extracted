use Test::More tests => 15;
use PerlX::Perform;

my %p;

isa_ok
	perform { 1 },
	'PerlX::Perform::Manifesto';

perform { $p{should_pass}++ } wherever 1;
ok $p{should_pass}, 'Things should be executed if scalar is defined';

perform { $p{zero}++ } wherever 0;
ok $p{zero}, 'Zero is still defined';

perform { $p{should_fail}++ } wherever undef;
ok !$p{should_fail}, 'Things should not be executed if scalar is undefined';

wherever 1, perform { $p{should_pass_2}++ };
ok $p{should_pass_2}, 'Things should be executed if scalar is defined (wherever first)';

wherever undef, perform { $p{should_fail_2}++ };
ok !$p{should_fail_2}, 'Things should not be executed if scalar is undefined (wherever first)';

wherever 1, sub { $p{should_pass_3}++ };
ok $p{should_pass_3}, 'Things should be executed if scalar is defined (wherever first, plain coderef)';

wherever undef, sub { $p{should_fail_3}++ };
ok !$p{should_fail_3}, 'Things should not be executed if scalar is undefined (wherever first, plain coderef)';

wherever 1, perform => perform { $p{should_pass_4}++ };
ok $p{should_pass_4}, 'Things should be executed if scalar is defined (wherever first, skip then plain coderef)';

wherever undef, perform => perform { $p{should_fail_4}++ };
ok !$p{should_fail_4}, 'Things should not be executed if scalar is undefined (wherever first, skip then plain coderef)';

perform { is $_, 123 } wherever 123;

perform { is ref($_), 'HASH' } wherever {};

perform { is(((caller(0))[0]), 'main') } wherever 2;

wherever 2, perform { is(((caller(0))[0]), 'main') };

perform { $p{no_wherever}++ } 1;
ok $p{no_wherever}, 'Wherever is actually optional';

