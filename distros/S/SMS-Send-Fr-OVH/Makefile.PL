use 5.020002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'SMS::Send::Fr::OVH',
    VERSION_FROM      => 'lib/SMS/Send/Fr/OVH.pm',
    PREREQ_PM         => { 'base' => 0,
                           'carp' => 0,
                           'LWP::Simple' => 0,
                           'SMS::Send::Driver' => 0,
                           'JSON' => 0,
                           'strict' => 0,
                           'warnings' => 0,
                         },
    ABSTRACT_FROM     => 'lib/SMS/Send/Fr/OVH.pm',
    AUTHOR            => 'Alex Arnaud <gg.alexarnaud@gmail.com>',
);
