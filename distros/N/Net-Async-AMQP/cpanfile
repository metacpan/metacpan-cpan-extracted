requires 'parent', 0;
requires 'curry', 0;
requires 'Future', '>= 0.30';
requires 'Mixin::Event::Dispatch', '>= 2.000';
requires 'IO::Async', '>= 0.63';
requires 'Net::AMQP', '>= 0.06';
requires 'Class::ISA', 0;
requires 'List::UtilsBy', 0;
requires 'File::ShareDir', 0;
requires 'IO::Socket::IP', 0;
requires 'Time::HiRes', 0;
requires 'List::UtilsBy', 0;
requires 'Variable::Disposition', '>= 0.004';
requires 'Log::Any', '>= 1.032';
requires 'Log::Any::Adapter', '>= 1.032';

recommends 'IO::Async::SSL', 0;

feature 'rpc', 'RPC Client/server support' => sub {
	requires 'UUID::Tiny', 0;
	recommends 'JSON::MaybeXS', 0;
};

feature 'protobuf', 'Google Protocol buffers encoding for RPC' => sub {
	requires 'Google::ProtocolBuffers', '>= 0.11';
};

on 'test' => sub {
	requires 'Test::More', '>= 0.98';
	requires 'Test::Fatal', '>= 0.010';
	requires 'Test::Refcount', '>= 0.07';
	requires 'Test::HexString', 0;
	recommends 'Test::MemoryGrowth', 0;
};
