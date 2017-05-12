use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SMS::Send::NANP::Raco_TMO',
    VERSION_FROM => 'lib/SMS/Send/NANP/Raco_TMO.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/SMS/Send/NANP/Raco_TMO.pm',
    PREREQ_PM    => {
                     'Test::Simple'                    => 0.44,
                     'SMS::Send::Driver::WebService'   => 0,
                     'XML::Simple'                     => 0,
                    },
);
