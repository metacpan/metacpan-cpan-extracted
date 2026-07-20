requires 'Acme::Bitfield';
requires 'Acme::Selection::RarestFirst';
requires 'Acme::UPnP';
requires 'Algorithm::Kademlia', 'v1.0.1';
requires 'Algorithm::RateLimiter::TokenBucket';
requires 'Crypt::URandom', '0.55';
requires 'Digest::Merkle::SHA256';
requires 'Digest::SHA';
requires 'HTTP::Tiny';
requires 'IO::Select';
requires 'IO::Socket::INET';
requires 'IO::Socket::IP';
requires 'Net::Multicast::PeerDiscovery';
requires 'Net::uTP';
requires 'Path::Tiny';
requires 'Socket';
requires 'URI';
requires 'URI::Escape';
requires 'perl', 'v5.42.0';
recommends 'Acme::UPnP';
recommends 'Crypt::PK::DH';
recommends 'Crypt::Perl::Ed25519::PublicKey';
recommends 'Crypt::Stream::RC4';
recommends 'IO::Async';
on configure => sub {
    requires 'Module::Build::Tiny';
    requires 'perl', 'v5.42.0';
};
on build => sub {
    requires 'Module::Build::Tiny';
};
on test => sub {
    requires 'Test2::V1';
};
