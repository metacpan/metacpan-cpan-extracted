#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Modbus::Client',
    VERSION_FROM	=> 'lib/Modbus/Client.pm',
    PREREQ_PM		=> { 'LWP::UserAgent' => 0 },
);
