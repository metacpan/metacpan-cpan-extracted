# CPAN dependencies for Mojolicious-Plugin-Fondation

# Minimum Perl version required (for Mojolicious signatures feature)
requires 'perl' => '5.026';

# Runtime dependencies
requires 'Hash::Merge' => '0.300';
requires 'Mojolicious' => '9.46';

# Testing dependencies
on test => sub {
    requires 'Test::More' => '1.00';
    requires 'Test::Mojo' => '0';
    requires 'File::Temp' => '0.01';
    requires 'File::Spec' => '3.00';
    requires 'File::Path' => '2.00';
};

# Development dependencies
on develop => sub {
    recommends 'Perl::Critic' => '1.00';
    recommends 'Perl::Tidy' => '20200000';
    recommends 'Pod::Checker' => '1.00';
};
