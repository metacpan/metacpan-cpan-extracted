use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SMS::Send::NANP::TextPower',
    VERSION_FROM => 'lib/SMS/Send/NANP/TextPower.pm',
    AUTHOR       => 'Michael R. Davis (mdavis@stopllc.com)',
    ABSTRACT_FROM=> 'lib/SMS/Send/NANP/TextPower.pm',
    PREREQ_PM    => {
                     'Test::Simple'                  => 0.44,
                     'SMS::Send::Driver::WebService' => 0.05,
                     'XML::Simple'                   => 0,
                    },
);
