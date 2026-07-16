# PAGI-Nano dependencies
# Install with: cpanm --installdeps .

# The core (lib/) runs on Perl back to 5.18; the examples use newer syntax.
requires 'perl', '5.018';

# Async primitives. Nano apps and handlers are written against Futures; the
# server owns the event loop.
requires 'Future', '0.50';
requires 'Future::AsyncAwait', '0.66';

# The base toolkit Nano is sugar over.
requires 'PAGI::Tools', '0.002002';

# The strong-parameters engine behind $c->params.
requires 'PAGI::StructuredParameters', '0.001000';

# Used directly to encode coerced hash/array returns as JSON. Already a
# PAGI-Tools dependency; declared explicitly because Nano use()s it itself.
requires 'JSON::MaybeXS', '1.004003';

# Testing
on 'test' => sub {
    requires 'Test2::V0', '0.000159';
    # In-process tests drive apps under a real event loop via PAGI::Test::Client.
    requires 'IO::Async', '0.802';
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
