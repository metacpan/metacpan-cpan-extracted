use Nefarious {
	Tester => {
		EXTENDS => 'Testing',
		five => sub {
			return 5;
		},
		six => sub {
			return 6;
		}
	}
};
1;
