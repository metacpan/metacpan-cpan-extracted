requires 'Crypt::AuthEnc::ChaCha20Poly1305';
requires 'Crypt::AuthEnc::GCM';
requires 'Crypt::Mac::HMAC';
requires 'Crypt::PK::X25519';
requires 'Digest::SHA';
requires 'perl', 'v5.42.0';
on configure => sub {
    requires 'Module::Build::Tiny';
};
on test => sub {
    requires 'IO::Socket::INET';
    requires 'Test2::V0';
};
