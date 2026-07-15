# CPAN dependencies for Mojolicious-Plugin-Fondation-SessionStore

requires 'perl' => '5.026';

# Runtime
requires 'Mojolicious' => '9.46';
requires 'Mojolicious::Plugin::Fondation';
requires 'Mojolicious::Sessions::Store';
requires 'Bytes::Random::Secure';

# Testing
on test => sub {
    requires 'Test::More' => '1.00';
    requires 'File::Temp' => '0.01';
    requires 'Test::Mojo';
};

# Development
on develop => sub {
    recommends 'Perl::Critic' => '1.00';
    recommends 'Perl::Tidy' => '20200000';
    recommends 'Pod::Checker' => '1.00';
};
