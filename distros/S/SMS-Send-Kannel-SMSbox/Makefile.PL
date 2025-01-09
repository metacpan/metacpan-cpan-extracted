use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'SMS::Send::Kannel::SMSbox',
    VERSION_FROM  => 'lib/SMS/Send/Kannel/SMSbox.pm',
    AUTHOR        => 'Michael R. Davis',
    ABSTRACT_FROM => 'lib/SMS/Send/Kannel/SMSbox.pm',
    LICENSE       => 'perl',
    PREREQ_PM     => {
                      'Test::Simple'                  => 0.44,
                      'SMS::Send::Driver::WebService' => 0.07,
                     },
    EXE_FILES     => [
                     qw{
                        scripts/perl-SMS-Send-Kannel-SMSbox-send_sms.pl
                       }
                     ],
  'META_MERGE' => {
    'resources' => {
      'repository' => {
        'web' => 'https://github.com/mrdvt92/perl-SMS-Send-Kannel-SMSbox.git',
        'url' => 'git@github.com:mrdvt92/perl-SMS-Send-Kannel-SMSbox.git',
        'type' => 'git'
      },
      'homepage' => 'https://github.com/mrdvt92/perl-SMS-Send-Kannel-SMSbox',
      'bugtracker' => {
        'web' => 'https://github.com/mrdvt92/perl-SMS-Send-Kannel-SMSbox/issues'
      }
    },
    'meta-spec' => {
      'version' => 2
    }
  }

);
