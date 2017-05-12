#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME    => 'SOAP::MIME',
    PREREQ_PM    => { 'SOAP::Lite' => 0.55 },
);
