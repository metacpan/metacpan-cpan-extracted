requires 'Exporter', '5.57';
requires 'Module::CPANfile', '1.1004';
requires 'Module::CoreList', '2.99';
requires 'Perl::PrereqScanner::NotQuiteLite', '0.9907';

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile', '0.06';
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
