requires 'Array::Diff' => '0.04';
requires 'Archive::Any::Lite' => '0.06';
requires 'Archive::Tar' => '1.76'; # filter_cb
requires 'Class::Accessor' => '0.19';
requires 'CPAN::Meta::YAML' => '0.008';
requires 'CPAN::Meta::Validator' => '2.133380';
requires 'Data::Binary' => '0';
requires 'File::Find::Object' => '0.2.1';
requires 'JSON::PP' => 0;
requires 'List::Util' => '1.33';
requires 'Module::Find';
requires 'Parse::Distname';
requires 'Perl::PrereqScanner::NotQuiteLite' => '0.9901';
requires 'perl' => '5.008001';
requires 'Software::License' => '0.103012';
requires 'Text::Balanced' => 0;
requires 'version' => '0.73';

suggests 'Module::CPANfile';
suggests 'Config::INI::Reader';

on configure => sub {
  requires 'ExtUtils::MakeMaker::CPANfile' => '0.08';
  requires 'perl' => '5.008001';
};

on test => sub {
  requires 'Cwd' => 0;
  requires 'Test::More' => '0.88';
  requires 'Test::FailWarnings' => 0;
};
