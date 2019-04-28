requires 'perl', '>= 5.024';
requires 'parent';
requires 'indirect';
requires 'Digest::MD5';
requires 'Time::HiRes';
requires 'POSIX';
requires 'Ryu', '>= 1.001';
requires 'Log::Any', '>= 1.050';
requires 'Check::UnitCheck', 0;
requires 'Future', '>= 0.39';
requires 'Sub::Identify';
requires 'Adapter::Async', 0;

on 'test' => sub {
	test_requires 'Test::More', '>= 0.98';
	test_requires 'Test::Fatal', '>= 0.010';
	test_requires 'Test::Refcount', '>= 0.07';
	test_requires 'Test::HexString', '>= 0.03';
	recommends 'Log::Any::Adapter::TAP', 0;
};

on 'develop' => sub {
    requires 'HTML::TreeBuilder', 0;
};

