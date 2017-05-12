use 5.008000;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'SMS::Send::Tellustalk',
    VERSION_FROM      => 'lib/SMS/Send/Tellustalk.pm',
    PREREQ_PM         => { HTTP::Tiny => 0, SMS::Send::Driver => 0, JSON => 0},
    NO_META           => 1,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM  => 'lib/SMS/Send/Tellustalk.pm',
            AUTHOR         => 'Eivin Giske Skaaren <eivin@sysmystic.com>') : ()),
);
