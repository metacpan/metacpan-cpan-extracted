use Test::More tests => 15;
use PerlX::Perform qw/perform whenever/;

my %p;

isa_ok
	perform { 1 },
	'PerlX::Perform::Manifesto';

perform { $p{should_pass}++ } whenever 1;
ok $p{should_pass}, 'Things should be executed if scalar is defined';

perform { $p{zero}++ } whenever 0;
ok $p{zero}, 'Zero is still defined';

perform { $p{should_fail}++ } whenever undef;
ok !$p{should_fail}, 'Things should not be executed if scalar is undefined';

whenever 1, perform { $p{should_pass_2}++ };
ok $p{should_pass_2}, 'Things should be executed if scalar is defined (whenever first)';

whenever undef, perform { $p{should_fail_2}++ };
ok !$p{should_fail_2}, 'Things should not be executed if scalar is undefined (whenever first)';

whenever 1, sub { $p{should_pass_3}++ };
ok $p{should_pass_3}, 'Things should be executed if scalar is defined (whenever first, plain coderef)';

whenever undef, sub { $p{should_fail_3}++ };
ok !$p{should_fail_3}, 'Things should not be executed if scalar is undefined (whenever first, plain coderef)';

whenever 1, perform => perform { $p{should_pass_4}++ };
ok $p{should_pass_4}, 'Things should be executed if scalar is defined (whenever first, skip then plain coderef)';

whenever undef, perform => perform { $p{should_fail_4}++ };
ok !$p{should_fail_4}, 'Things should not be executed if scalar is undefined (whenever first, skip then plain coderef)';

perform { is $_, 123 } whenever 123;

perform { is ref($_), 'HASH' } whenever {};

perform { is(((caller(0))[0]), 'main') } whenever 2;

whenever 2, perform { is(((caller(0))[0]), 'main') };

perform { $p{no_whenever}++ } 1;
ok $p{no_whenever}, 'whenever is actually optional';

