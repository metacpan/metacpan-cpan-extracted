use ExtUtils::MakeMaker;
WriteMakefile(
  NAME           => 'RPM::Query',
  LICENSE        => 'MIT',
  VERSION_FROM   => 'lib/RPM/Query.pm',
  PREREQ_PM      => {
                     'Package::New' => 0,
                     'List::Util'   => 1.45,
                     'IPC::Run3'    => 0,
                    },
  ABSTRACT_FROM  => 'lib/RPM/Query.pm',
  AUTHOR         => 'Michael R. Davis',
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-RPM-Query.git',
        'url' => 'git@github.com:mrdvt92/perl-RPM-Query.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-RPM-Query',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-RPM-Query/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
