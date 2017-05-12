use Module::Build;
my $build = Module::Build->new(
  module_name => 'Pod::Perldocs',
  license => 'perl',
  requires => {
               'Pod::Perldoc' => '0.1',
               'LWP' => '0',
              },
  dist_version_from => 'lib/Pod/Perldocs.pm',
  dist_author => ['Randy Kobes <r.kobes@uwinnipeg.ca>'],
  dist_abstract => 'view remote pod via Pod::Perldoc',
  script_files => ['bin/perldocs'],
);
$build->create_build_script;

