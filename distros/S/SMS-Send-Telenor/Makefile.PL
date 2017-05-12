use 5.008000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'SMS::Send::Telenor',
    VERSION_FROM      => 'lib/SMS/Send/Telenor.pm',
    PREREQ_PM         => { HTTP::Tiny => 0, SMS::Send::Driver => 0 },
    NO_META           => 1,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM  => 'lib/SMS/Send/Telenor.pm',
            AUTHOR         => 'Eivin Giske Skaaren <eivin@sysmystic.com>') : ()),
);
