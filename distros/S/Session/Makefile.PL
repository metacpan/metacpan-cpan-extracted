use strict;
use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Session',
    DISTNAME        => 'Session',
    VERSION_FROM    => 'Session.pm', # finds $VERSION
    PREREQ_PM       => {'Apache::Session' => 1.54},
    ABSTRACT_FROM   => 'Session.pm', # retrieve abstract from module
    AUTHOR          => 'Olivier Poitrey <rs@rhapsodyk.net>',
);
