use Nefarious {
	Basic => {
		str => 'abc',
		one => sub {
			return 1;
		},
		two => sub {
			return 2;
		},
	}
};

1;
