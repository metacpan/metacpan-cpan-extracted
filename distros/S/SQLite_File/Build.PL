use Module::Build;

Module::Build->new
  ( dist_name        => 'SQLite_File',
    dist_abstract    => 'DB_File emulator with SQLite backend',
    dist_version_from => 'lib/SQLite_File.pm',
    dist_author      => 'Mark A. Jensen',
    requires           => {
      perl                          => '5.010',
      'DBD::SQLite'                 => '1.25',
      'Fcntl'                       => 0
     },
    configure_requires => {
      'Module::Build' => '0.30'
     },
    build_requires     => {
      'DBI'                         => 0,
      'AnyDBM_File'                 => 0,
      'AnyDBM_File::Importer'       => 0,
      'File::Temp'                  => 0,
      'Module::Build'               => '0.30',
      'TAP::Harness'                => 0
     },
    recommends         => {
      'AnyDBM_File::Importer'       => 0
     },
    license            => 'perl',
    use_tap_harness => 1,
    tap_harness_args => {
      rules => { seq => 't/*.t'},
    },
    meta_merge => {
      resources => {
	bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=SQLite_File',
	repository  => 'http://github.com/majensen/sqlite_file.git',
      }
     },
   )->create_build_script;
