requires 'perl', '5.024';
requires 'indirect',    '>= 0.37';
requires 'Future::AsyncAwait', '>= 0.23';
requires 'IO::Async::SSL', 0;
requires 'JSON::MaybeXS', 0;
requires 'JSON::MaybeUTF8', '>= 1.002';
requires 'Digest::Keccak', 0;
requires 'Math::BigFloat', '>= 1.999814';
requires 'Math::BigInt', '>= 1.999814';
requires 'Net::Async::WebSocket', '>= 0.13';
requires 'Net::Async::HTTP', '>= 0.43';
requires 'Ryu::Async', '>= 0.011';
requires 'Syntax::Keyword::Try', '>= 0.09';
requires 'ZMQ::LibZMQ3', '>= 1.19';
requires 'IO::Async::Timer::Periodic', '>= 0.72';

on test => sub {
    requires 'Test::More', '>= 0.98';
    requires 'Test::MockModule', 0;
    requires 'Test::MemoryGrowth', >= 0.03;
    requires 'Test::Exception', 0;
};

on develop => sub {
    requires 'Devel::Cover', '>= 1.23';
    requires 'Devel::Cover::Report::Codecov', '>= 0.14';
};
