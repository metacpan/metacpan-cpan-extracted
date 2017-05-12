#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Net::Amazon::S3::Client::GPG',
    VERSION_FROM => 'lib/Net/Amazon/S3/Client/GPG.pm',
    ABSTRACT     => 'Use GPG with Amazon S3 - Simple Storage Service',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'GnuPG::Interface' => '0',
        'Net::Amazon::S3'  => '0',
        'Test::More'       => '0',

    }
);

