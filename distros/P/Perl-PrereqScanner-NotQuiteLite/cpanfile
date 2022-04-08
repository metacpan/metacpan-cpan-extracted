requires 'CPAN::Meta::Prereqs', '2.150010';
requires 'CPAN::Meta::Requirements', '2.140';
requires 'Data::Dump';
requires 'Exporter', '5.57';
requires 'Module::CPANfile', '1.1004';
requires 'Module::CoreList', '3.11';
requires 'Module::Find';
requires 'Parse::Distname';
requires 'Regexp::Trie';
requires 'parent';
requires 'perl', '5.008001';
suggests 'JSON::PP';
suggests 'CPAN::Common::Index';

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile', '0.06';
};

on test => sub {
    requires 'Test::FailWarnings';
    requires 'Test::More', '0.98';
    requires 'Test::UseAllModules', '0.17';
};

on develop => sub {
    requires 'Archive::Any::Lite';
    requires 'CPAN::DistnameInfo';
    requires 'Data::Dump';
    requires 'Exporter', '5.57';
    requires 'JSON::XS';
    requires 'Log::Handler';
    requires 'Module::ExtractUse';
    requires 'Package::Abbreviate';
    requires 'Path::Tiny';
    requires 'Perl::PrereqScanner';
    requires 'Test::More', '0.88';
    requires 'Time::Piece';
    requires 'Test::CPANfile', '0.06';
    suggests 'Perl::PrereqScanner::Lite';
    suggests 'Test::Pod', '1.18';
};
