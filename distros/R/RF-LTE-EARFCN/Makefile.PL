use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'RF::LTE::EARFCN',
    VERSION_FROM      => 'lib/RF/LTE/EARFCN.pm',
    PREREQ_PM         => {
                          'Package::New' => 0, #new
                          'Carp'         => 0, #croak
                         },
    ABSTRACT_FROM     => 'lib/RF/LTE/EARFCN.pm',
    AUTHOR            => 'Michael R. Davis <mrdvt92@yahoo.com>',
    LICENSE           => 'mit',
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-RF-LTE-EARFCN.git',
        'type' => 'git',
        'url' => 'git@github.com:mrdvt92/perl-RF-LTE-EARFCN.git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-RF-LTE-EARFCN',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-RF-LTE-EARFCN/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  },
);
