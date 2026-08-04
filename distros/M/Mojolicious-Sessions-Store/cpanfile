# CPAN dependencies for Mojolicious-Sessions-Store

requires 'perl' => '5.026';

# Runtime
requires 'Mojolicious' => '9.46';
recommends 'Crypt::PRNG' => '0.090';

# Testing
on test => sub {
    requires 'Test::More' => '1.00';
    requires 'File::Temp' => '0.01';
    requires 'File::Spec' => '3.00';
    requires 'FindBin' => '1.00';
};

# Development
on develop => sub {
    recommends 'Perl::Critic' => '1.00';
    recommends 'Perl::Tidy' => '20200000';
    recommends 'Pod::Checker' => '1.00';
};
