use strict;
use Module::Build;

my $build = Module::Build->new(
  module_name => 'Module::CPANTS::Generator',
  license     => 'perl',
  requires    => {
    'CPANPLUS'    => '0.042',
    'DBD::SQLite' => '0.01',
    'File::Find::Rule' => '0.01',
    'LWP::Simple' => '0.01',
    'Pod::POM'  => '0.01',
    'Pod::Simple'  => '0.01',
    'String::Approx'  => '0.01',
    'Template'    => '2.08',
    'Test::More'  => '0.01',
  },
);
$build->create_build_script;
