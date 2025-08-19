
use Test::Most;

BEGIN { use_ok('Readonly::Enum') }

subtest 'basic incrementing' => sub {
	Readonly::Enum my ($a, $b, $c);
	is $a, 1;
	is $b, 2;
	is $c, 3;
};

subtest 'custom start value' => sub {
	Readonly::Enum my ($x, $y, $z) => 5;
	is_deeply [$x, $y, $z], [5, 6, 7];
};

subtest 'multiple starts' => sub {
	Readonly::Enum my ($a, $b, $c) => (0, 5);
	is $a, 0;
	is $b, 5;
	is $c, 6;
};

subtest 'too many values' => sub {
	throws_ok { Readonly::Enum my ($a) => (1, 2, 3) } qr/too many initial values/i;
};

subtest 'invalid non-integer' => sub {
	throws_ok { Readonly::Enum my ($a, $b) => ('foo') } qr/integer/i;
};

subtest 'no args' => sub {
	lives_ok { Readonly::Enum() };
};

done_testing();
