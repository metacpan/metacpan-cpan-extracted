requires 'parent', 0;
requires 'curry', '>= 1.001';
requires 'namespace::clean', 0;

requires 'URI::udp', 0;
requires 'URI::tcp', 0;
requires 'Log::Any', '>= 1.050';
requires 'Ryu', '>= 2.006';
requires 'Future', '>= 0.45';
requires 'IO::Async', '>= 0.71';
requires 'IO::Socket::IP', '>= 0.37';

requires 'Syntax::Keyword::Try';

recommends 'Heap', 0;
recommends 'IO::Async::SSL', '>= 0.19';

recommends 'IO::AsyncX::Sendfile', '>= 0.002';
recommends 'IO::AsyncX::System', '>= 0.003';

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';

	requires 'indirect', 0;
	requires 'Variable::Disposition', '>= 0.004';
	requires 'Test::Deep', '>= 1.126';
};

on 'develop' => sub {
    requires 'Devel::Cover';
    requires 'Devel::Cover::Report::Coveralls', '>= 0.11';
};
