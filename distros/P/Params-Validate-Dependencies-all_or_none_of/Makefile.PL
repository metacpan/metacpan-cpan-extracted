use ExtUtils::MakeMaker;
WriteMakefile(
  NAME         => 'Params::Validate::Dependencies::all_or_none_of',
    META_MERGE => {
        license => 'open_source',
        resources => {
	    repository => 'https://github.com/DrHyde/perl-modules-Params-Validate-Dependencies-all_or_none_of',
	    bugtracker => 'https://github.com/DrHyde/perl-modules-Params-Validate-Dependencies-all_or_none_of/issues'
        }
    },
  VERSION_FROM => 'lib/Params/Validate/Dependencies/all_or_none_of.pm',
  PREREQ_PM    => {
    'Params::Validate::Dependencies' => 1.22,
    'Test::More'                     => 0.88, # done_testing
  },
);
