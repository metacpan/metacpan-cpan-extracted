requires 'CPAN::Meta::Prereqs' => '2.113640';
requires 'CPAN::Meta::Requirements' => '2.113640';
requires 'Exporter' => '5.57'; # for import
requires 'Module::Find';

suggests 'Data::Dump';

on test => sub {
  requires 'Test::More' => '0.98'; # for sane subtest
  requires 'Test::UseAllModules' => '0.10';
};

on configure => sub {
  requires 'ExtUtils::MakeMaker::CPANfile' => '0.06';
};

on develop => sub {
  requires 'Archive::Any::Lite';
  requires 'CPAN::DistnameInfo';
  requires 'Data::Dump';
  requires 'Log::Handler';
  requires 'Package::Abbreviate';
  requires 'Path::Tiny';
  requires 'Time::Piece';
};
