use strict;
use warnings;

on 'runtime' => sub {
    requires 'Pod::Text' => '4.00';    # to avoid issues with wrong test results
    requires 'Pod::Simple' => '3.40';  # to avoid issues with wrong test results
    requires 'Pod::Perldoc' => '3.28';  # to avoid issues with wrong test results
    requires 'Cwd';
    requires 'File::Basename';
    requires 'File::Spec' => '0.82';
};

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'test' => sub {
    requires 'Test::More' => '0.60';
    requires 'blib';
};

on 'develop' => sub {
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::CheckManifest' => '1.29';
    requires 'Test::CPAN::Changes' => '0.4';
    requires 'Test::CPAN::Meta';
    requires 'Test::Kwalitee' => '1.22';
    requires 'Test::Pod::Coverage';
    requires 'Test::Pod::Spelling::CommonMistakes' => '1.000';
};
