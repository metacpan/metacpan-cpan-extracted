use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'REST::Application',
    'VERSION_FROM' => 'lib/REST/Application.pm', 
    'PREREQ_PM' => { 
        'CGI' => 0,
        'Tie::IxHash' => 0,
    },
    ABSTRACT   => 'A framework for building RESTful Applications.',
    AUTHOR     => 'Matthew O\'Connor <matthew@canonical.org>',
);
