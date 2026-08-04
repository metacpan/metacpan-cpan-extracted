# CPAN dependencies for Mojolicious-Plugin-Fondation-Auth-Token

requires 'perl' => '5.026';

# Runtime
requires 'Mojolicious' => '9.46';
requires 'Mojolicious::Plugin::Fondation';
requires 'Mojolicious::Plugin::Fondation::Model::DBIx::Async';
requires 'Mojolicious::Plugin::Fondation::Auth';
requires 'Mojolicious::Plugin::Fondation::Problem';

requires 'Digest::SHA';
requires 'Crypt::URandom';

# Testing
on test => sub {
    requires 'Test::More' => '1.00';
    requires 'File::Temp' => '0.01';
    requires 'Test::Mojo';
};
