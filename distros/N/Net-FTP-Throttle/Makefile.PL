#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Net::FTP::Throttle',
    'VERSION_FROM' => 'lib/Net/FTP/Throttle.pm',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'PREREQ_PM' => {
        'Algorithm::TokenBucket' => '0',
        'Net::FTP'               => '2.75',
        'Time::HiRes'            => '0'
    },
    'INSTALLDIRS' => 'site',
    'PL_FILES'    => {}
);
