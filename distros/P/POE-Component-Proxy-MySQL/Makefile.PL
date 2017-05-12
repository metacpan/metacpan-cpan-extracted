use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::Proxy::MySQL',
    AUTHOR              => 'Eriam Schaffter <eriam@cpan.org>',
    VERSION_FROM        => 'lib/POE/Component/Proxy/MySQL.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/Proxy/MySQL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'                => 0,
        'MySQL::Packet'             => 0,
        'Moose'                     => 0,
        'MooseX::MethodAttributes'  => 0,
        'POE'                       => 0,
        'Time::HiRes'               => 0,
        'Class::Inspector'          => 0,
        'Module::Find'              => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-Proxy-MySQL-*' },
);
