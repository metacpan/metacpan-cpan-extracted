use 5.020002;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'SMS::Send::Orange::ContactEveryone',
    VERSION_FROM      => 'lib/SMS/Send/Orange/ContactEveryone.pm',
    PREREQ_PM         => { 'base' => 0,
                           'Carp' => 1.20,
                           'XML::Simple' => 2.20,
                           'LWP::UserAgent' => 6.06,
                           'HTTP::Request' => 6.00,
                           'SMS::Send::Driver' => 0,
                           'strict' => 0,
                           'warnings' => 0
                         },
    ABSTRACT_FROM     => 'lib/SMS/Send/Orange/ContactEveryone.pm',
    AUTHOR            => 'Alex Arnaud <gg.alexarnaud@gmail.com>',
);
