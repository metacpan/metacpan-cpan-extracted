requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'perl', '5.008001';

on configure => sub {
    requires 'ExtUtils::MakeMaker', '6.30';
};

on test => sub {
    requires 'File::Temp';
    requires 'Test::More';
    requires 'Test::Output';
};

on develop => sub {
    requires 'Test::LeakTrace';
    requires 'Test::Perl::Critic';
};
