use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Module::Filename',
    VERSION_FROM => 'lib/Module/Filename.pm',
    AUTHOR       => 'Michael R. Davis (MRDVT)',
    ABSTRACT     => 'Returns the filename for a given module',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Path::Class'  => 0,
                     'strict'       => 0,
                    },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Module-Filename.git',
        'url' => 'git@github.com:mrdvt92/perl-Module-Filename.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Module-Filename',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Module-Filename/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
