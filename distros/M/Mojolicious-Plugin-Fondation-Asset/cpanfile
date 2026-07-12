# CPAN dependencies for Mojolicious-Plugin-Fondation-Asset
# This file is used by cpanminus (cpanm) and Carton

# Minimum Perl version required (for Mojolicious signatures feature)
requires 'perl' => '5.026';

# Runtime dependencies
requires 'Mojolicious' => '9.46';  # Mojolicious 9.00+ for -signatures support
requires 'Mojolicious::Plugin::Fondation' => '0.01';
requires 'Mojolicious::Plugin::AssetPack' => '2.15';
requires 'YAML::XS' => '0.90';
requires 'CSS::Minifier::XS' => '0.13';

# Testing dependencies
on test => sub {
    requires 'Test::More' => '1.00';
};

# Development dependencies (for author)
on develop => sub {
    # Dist::Zilla dependencies are managed by dist.ini
    # These are additional tools for development
    recommends 'Perl::Critic' => '1.00';
    recommends 'Perl::Tidy' => '20200000';
    recommends 'Pod::Checker' => '1.00';
};