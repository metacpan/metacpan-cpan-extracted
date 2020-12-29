use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'SMS::Send::Adapter::Node::Red',
    VERSION_FROM   => 'lib/SMS/Send/Adapter/Node/Red.pm',
    PREREQ_PM      => { 
                       'Package::New'        => 0,
                       'SMS::Send'           => 0,
                       'CGI'                 => 0,
                       'JSON'                => 0,
                       'SMS::Send::VoIP::MS' => 0, #tests only
                      },
    ABSTRACT_FROM  => 'lib/SMS/Send/Adapter/Node/Red.pm',
    AUTHOR         => 'Michael R. Davis',
);
