# CPAN dependencies for Mojolicious-Plugin-Fondation-Setup

requires 'perl' => '5.026';

# Runtime dependencies
requires 'Mojolicious' => '9.46';
requires 'Mojolicious::Plugin::Fondation::Layout::Bootstrap' => '0.01';
requires 'Mojolicious::Plugin::Fondation::SessionStore'      => '0.01',

requires 'YAML::XS' => '0.01';

# Testing dependencies
on test => sub {
    requires 'Test::More' => '1.00';
    requires 'File::Temp' => '0.01';
    requires 'File::Spec' => '3.00';
    requires 'FindBin' => '1.00';
};

# Development dependencies
on develop => sub {
    recommends 'Perl::Critic' => '1.00';
    recommends 'Perl::Tidy' => '20200000';
    recommends 'Pod::Checker' => '1.00';
};
