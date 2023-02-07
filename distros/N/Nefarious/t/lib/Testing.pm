use Nefarious {
	Testing => {
		EXTENDS => 'Test',
		three => sub {
			return 3;
		},
		four => sub {
			return 4;
		},
	}
};
1;
