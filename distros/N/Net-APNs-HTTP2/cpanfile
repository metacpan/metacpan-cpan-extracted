requires 'AnyEvent';
requires 'AnyEvent::Handle';
requires 'AnyEvent::Socket';
requires 'Cache::Memory::Simple';
requires 'Crypt::JWT';
requires 'Crypt::PK::ECC', '0.059';
requires 'JSON';
requires 'Moo';
requires 'Protocol::HTTP2::Client';
requires 'perl', '5.010';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
};
