use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SMS::Send::Driver::WebService',
    VERSION_FROM => 'lib/SMS/Send/Driver/WebService.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/SMS/Send/Driver/WebService.pm',
    PREREQ_PM    => {
                     'Test::Simple'     => 0.44,
                     'LWP::UserAgent'   => 0,
                     'SMS::Send'        => 0,
                     'Config::IniFiles' => 0,
                     'Path::Class'      => 0,
                    },
);
