#!/usr/bin/perl

use warnings;
use strict;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                =>  'RTPG',
    AUTHOR              => 'Dmitry E. Oboukhov <unera@debian.org>',
    VERSION_FROM        => './RTPG.pm',
    ABSTRACT_FROM       => './RTPG.pm',
    NO_META             => 0,
    PREREQ_PM           => {
        Carp                => 0,
        'RPC::XML::Client'  => 0,
        'RPC::XML'          => 0,
        'RPC::XML::Parser'  => 0,
        'MIME::Types'       => 0,
        Encode              => 0,
    },
);
