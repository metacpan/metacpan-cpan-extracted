use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'SMS::Send::Driver::WebService',
    VERSION_FROM  => 'lib/SMS/Send/Driver/WebService.pm',
    AUTHOR        => 'Michael R. Davis (mrdvt)',
    ABSTRACT_FROM => 'lib/SMS/Send/Driver/WebService.pm',
    LICENSE       => 'mit',
    PREREQ_PM     => {
                      'Test::Simple'     => 0.44,
                      'LWP::UserAgent'   => 0,
                      'HTTP::Tiny'       => 0,
                      'SMS::Send'        => 0,
                      'URI'              => 0,
                      'Config::IniFiles' => 0,
                      'Path::Class'      => 0,
                     },
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-SMS-Send-Driver-WebService.git',
        'url' => 'git@github.com:mrdvt92/perl-SMS-Send-Driver-WebService.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-SMS-Send-Driver-WebService',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-SMS-Send-Driver-WebService/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  }
);
