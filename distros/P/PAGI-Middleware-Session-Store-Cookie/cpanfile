# PAGI::Middleware::Session::Store::Cookie dependencies

requires 'perl', '5.018';

# Core PAGI session interface
requires 'PAGI', '0.001020';

# Encryption
requires 'CryptX', '0.080';

# Serialization
requires 'JSON::MaybeXS', '1.004003';

# Async interface
requires 'Future', '0.50';

# Testing
on 'test' => sub {
    requires 'Test2::V0', '0.000159';
    requires 'Future::AsyncAwait', '0.66';
};

# Development
on 'develop' => sub {
    requires 'Dist::Zilla', '6.030';
    requires 'Dist::Zilla::Plugin::MetaJSON';
    requires 'Dist::Zilla::Plugin::MetaResources';
    requires 'Dist::Zilla::Plugin::MetaNoIndex';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
};
