requires 'Exporter', '5.57';
requires 'Module::CPANfile';
requires 'Module::CoreList', '2.99';
requires 'Perl::PrereqScanner::NotQuiteLite', '0.9902';

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile';
};

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::UseAllModules', '0.17';
    requires 'CPAN::Common::Index';
};

on develop => sub {
    suggests 'Test::Pod', '1.18';
    suggests 'Test::Pod::Coverage', '1.04';
};
