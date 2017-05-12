use Module::Build;

Module::Build->new
  (
    module_name     => 'PerlIO::via::gzip',
    license         => 'perl',
    requires        => {
      'IO::Compress::Gzip'  => 2,
      'IO::Uncompress::Gunzip'  => 2,
    },
    configure_requires => {
      'Module::Build'       => 0,
    },
    meta_merge => {
      resources => {
	bugtracker => 'https://github.com/majensen/perlio-via-gzip/issues',
	repository => 'https://github.com/majensen/perlio-via-gzip.git'
       }
    }
   )->create_build_script;
