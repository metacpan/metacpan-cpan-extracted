use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Package::New',
    VERSION_FROM  => 'lib/Package/New.pm',
    AUTHOR        => 'Michael R. Davis',
    LICENSE       => 'bsd',
    ABSTRACT_FROM => 'lib/Package/New.pm',
    PREREQ_PM     => {
                      'Test::Simple' => 0.44,
                      'Devel::Hide'  => 0,
                     },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-Package-New.git',
        'url' => 'git@github.com:mrdvt92/perl-Package-New.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-Package-New',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-Package-New/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
