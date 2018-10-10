use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SMS::Send::Kannel::SMSbox',
    VERSION_FROM => 'lib/SMS/Send/Kannel/SMSbox.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/SMS/Send/Kannel/SMSbox.pm',
    PREREQ_PM    => {
                     'Test::Simple'                  => 0.44,
                     'SMS::Send::Driver::WebService' => 0,
                    },
    EXE_FILES    => [
                    qw{
                       scripts/perl-SMS-Send-Kannel-SMSbox-send_sms.pl
                      }
                    ],
);
