use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Nagios::NSCA',
    'VERSION' => '0.1', 
    'EXE_FILES' => ['bin/send_nsca'],
    'PREREQ_PM' => {
        'Digest::CRC' => 0,
        'IO::Socket::INET' => 0,
    },
    ABSTRACT   => 'A Perl implementation of the Nagios NSCA Client/Server.',
    AUTHOR     => 'Matthew O\'Connor <matthew@canonical.org>',
);
