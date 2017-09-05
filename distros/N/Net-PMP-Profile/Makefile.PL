#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;
use 5.008003;

name 'Net-PMP-Profile';
all_from 'lib/Net/PMP/Profile.pm';

requires 'Moose'                       => 0;
requires 'Test::More'                  => 0;
requires 'Test::Exception'             => 0;
requires 'Net::PMP'                    => '0.001';
requires 'URI'                         => 0;
requires 'URI::Template'               => 0;
requires 'UUID::Tiny'                  => 0;
requires 'DateTime'                    => '1.44';
requires 'DateTime::Format::DateParse' => 0;
requires 'DateTime::Format::Strptime'  => 0;
requires 'Data::Validate::URI'         => 0;
requires 'Media::Type::Simple'         => 0;
requires 'Data::Clean::JSON'           => 0;

perl_version '5.8.3';
license 'MIT';
homepage 'https://github.com/APMG/net-pmp-profile-perl';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-PMP-Profile';
repository 'http://github.com/APMG/net-pmp-profile-perl';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-PMP-Profile-*.tar.gz' },
);

