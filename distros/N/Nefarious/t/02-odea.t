use Types::Standard qw/Str/;
use Nefarious {
	Test => {
		str => 'abc',
		fact => [
			[Str, Str, sub {
				return 'two strings';
			}],
			[Str, sub {
				return 'one string';
			}],
			sub {
				return 'default';
			}
		],
		one => sub {
			return 1;
		},
		two => sub {
			return 2;
		},
		Testing => {
			three => sub {
				return 3;
			},
			four => sub {
				return 4;
			},
			Tester => {
				five => sub {
					return 5;
				},
				six => sub {
					return 6;
				}
			}
		}
	}
};

use Test::More;
use Test;

my $t = Test->new();

is($t->one, 1);
is($t->two, 2);

$t = Testing->new();

is($t->one, 1);
is($t->two, 2);
is($t->three, 3);
is($t->four, 4);

$t = Tester->new();

is($t->one, 1);
is($t->two, 2);
is($t->three, 3);
is($t->four, 4);
is($t->five, 5);
is($t->six, 6);
is($t->str, 'abc');
is($t->fact('abc', 'def'), 'two strings');
is($t->fact('abc'), 'one string');
is($t->fact, 'default');

done_testing();
