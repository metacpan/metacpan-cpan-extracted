use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'SMS::Send::VoIP::MS',
    VERSION_FROM   => 'lib/SMS/Send/VoIP/MS.pm',
    PREREQ_PM      => {
                       'SMS::Send::Driver::WebService' => 0, #base package
                       'URI'                           => 0,
                       'JSON::XS'                      => 0,
                       'Test::Simple'                  => 0, #Test::More
                       'Path::Class'                   => 0, #for tests
                      },
    ABSTRACT_FROM  => 'lib/SMS/Send/VoIP/MS.pm',
    AUTHOR         => 'Michael R. Davis <mrdvt92>',
    LICENSE        => 'mit',
    EXE_FILES    => [
                    qw{
                       scripts/perl-SMS-Send-VoIP-MS-send_sms.pl
                      }
                    ],
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-SMS-Send-VoIP-MS.git',
        'url' => 'git@github.com:mrdvt92/perl-SMS-Send-VoIP-MS.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-SMS-Send-VoIP-MS',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-SMS-Send-VoIP-MS/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  }
);
