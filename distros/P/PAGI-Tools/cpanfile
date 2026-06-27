# PAGI-Tools dependencies
# Install with: cpanm --installdeps .

requires 'perl', '5.018';

# Async primitives (apps and middleware are written against Futures;
# no event loop dependency — the server owns the loop)
requires 'Future', '0.50';
requires 'Future::AsyncAwait', '0.66';

# Loop-agnostic async I/O (PAGI::SSE->every, timers in apps)
recommends 'Future::IO', '0.23';

# Body/header processing
requires 'JSON::MaybeXS', '1.004003';
requires 'Hash::MultiValue', '0.16';
requires 'Cookie::Baker', '0.11';
requires 'HTTP::MultiPartParser', '0.02';

# Response compression (PAGI::Middleware::GZip; WebSocket permessage-deflate).
# Both ship with core Perl; declared so the dependency is explicit.
requires 'IO::Compress::Gzip';
recommends 'Compress::Raw::Zlib';

# Date parsing for PAGI::Middleware::ConditionalGet
requires 'HTTP::Date', '6.06';

# Fast JSON (optional)
recommends 'Cpanel::JSON::XS', '4.19';

# Secure random fallback for systems without /dev/urandom
# (PAGI::Utils::Random degrades gracefully without it)
recommends 'Crypt::URandom', '0.36';

# Testing
on 'test' => sub {
    requires 'Test2::V0', '0.000159';
    # In-process tests drive apps under a real event loop
    requires 'IO::Async', '0.802';
    # tutorial.t exercises Future::IO patterns (self-skips when absent,
    # but CI should run it)
    requires 'Future::IO', '0.23';
    requires 'Time::HiRes', '1.9764';
};

# Development
on 'develop' => sub {
    requires 'Dist::Zilla', '6.030';
    requires 'Dist::Zilla::Plugin::MetaJSON';
    requires 'Dist::Zilla::Plugin::MetaResources';
    requires 'Dist::Zilla::Plugin::MetaNoIndex';
    requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
    requires 'Dist::Zilla::Plugin::PkgVersion';
    requires 'Dist::Zilla::Plugin::ReadmeAnyFromPod';
};
