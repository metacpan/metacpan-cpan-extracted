#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::MythTV',
    VERSION_FROM => 'lib/Net/MythTV.pm',
    ABSTRACT     => 'Interface to MythTV',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'DateTime'                  => '0',
        'URI'                       => '0',
        'Moose'                     => '0',
        'MooseX::StrictConstructor' => '0',
    }
);

