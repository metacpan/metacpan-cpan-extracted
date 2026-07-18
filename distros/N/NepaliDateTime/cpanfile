# cpanfile – dependency manifest for NepaliDateTime
# Install all dependencies:   cpanm --installdeps .
# Run tests after install:    prove -Ilib -r t/

requires 'perl', '5.12.0';
requires 'Carp';          # core – explicit for completeness
requires 'POSIX';         # core – explicit for completeness

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker', '6.64';
};

on 'test' => sub {
    requires 'Test2::V1', '1.302218';   
    requires 'FindBin';                    # core
};

on 'develop' => sub {
    requires 'Dist::Zilla';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Pod',          '1.22';
    requires 'Test::Pod::Coverage', '1.08';
};
