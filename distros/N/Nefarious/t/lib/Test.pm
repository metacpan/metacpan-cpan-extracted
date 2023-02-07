use Types::Standard;
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
	}
};
1;
