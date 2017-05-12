#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;
use 5.008003;

name 'Net-PMP';
all_from 'lib/Net/PMP.pm';

requires 'Moose'                       => 0;
requires 'MooseX::SimpleConfig'        => 0;
requires 'MooseX::Getopt'              => 0;
requires 'Try::Tiny'                   => 0;
requires 'Test::More'                  => 0;
requires 'JSON'                        => 2.0;
requires 'LWP::UserAgent'              => 0;
requires 'LWP::Protocol::https'        => 0;
requires 'Data::Dump'                  => 0;
requires 'URI'                         => 0;
requires 'URI::Template'               => 0;
requires 'UUID::Tiny'                  => 0;
requires 'Data::Validate::URI'         => 0;

perl_version '5.8.3';
license 'MIT';
homepage 'https://github.com/APMG/pmp-sdk-perl';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP';
repository 'http://github.com/APMG/pmp-sdk-perl';
install_script 'bin/pmpc';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-PMP-*tar.gz' },
);
