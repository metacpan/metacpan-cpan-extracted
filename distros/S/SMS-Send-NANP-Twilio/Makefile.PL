use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'SMS::Send::NANP::Twilio',
    VERSION_FROM   => 'lib/SMS/Send/NANP/Twilio.pm',
    PREREQ_PM      => {
                        'URI'                           => 0,
                        'JSON::XS'                      => 0,
                        'DateTime'                      => 0, #tests
                        'SMS::Send::Driver::WebService' => 0.06,
                      },
    ABSTRACT_FROM  => 'lib/SMS/Send/NANP/Twilio.pm',
    AUTHOR         => 'Michael Davis <mrdvt>',
    'META_MERGE'   => {
                        'resources' => {
                          'repository' => {
                            'web' => 'https://github.com/mrdvt92/perl-SMS-Send-NANP-Twilio.git',
                            'url' => 'git@github.com:mrdvt92/perl-SMS-Send-NANP-Twilio.git',
                            'type' => 'git'
                          },
                          'homepage' => 'https://github.com/mrdvt92/perl-SMS-Send-NANP-Twilio',
                          'bugtracker' => {
                            'web' => 'https://github.com/mrdvt92/perl-SMS-Send-NANP-Twilio/issues'
                          }
                        },
                        'meta-spec' => {'version' => 2},
                      },

);
