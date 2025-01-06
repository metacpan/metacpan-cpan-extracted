use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'String::ProperCase::Surname',
    VERSION_FROM   => 'lib/String/ProperCase/Surname.pm',
    ABSTRACT_FROM  => 'lib/String/ProperCase/Surname.pm',
    AUTHOR         => 'Michael R. Davis',
    LICENSE        => 'bsd',
    PREREQ_PM      => {
                       'Test::Simple' => 0.44,
                      },
    EXE_FILES      => [
                      qw{
                         scripts/perl-String-ProperCase-Surname.pl
                        }
                      ],
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-String-ProperCase-Surname.git',
        'url' => 'git@github.com:mrdvt92/perl-String-ProperCase-Surname.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-String-ProperCase-Surname',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-String-ProperCase-Surname/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
