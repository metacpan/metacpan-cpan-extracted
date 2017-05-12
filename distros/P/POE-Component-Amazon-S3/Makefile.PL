#!/usr/bin/perl

use strict;
use ExtUtils::MakeMaker;

my %prereq = (
    'Data::Dump'                   => 0,
    'Digest::HMAC_SHA1'            => 0,
    'HTTP::Date'                   => 0,
    'MIME::Base64'                 => 0,
    'POE'                          => 0,
    'POE::Component::Client::HTTP' => 0.81,
    'URI::Escape'                  => 0,
    'XML::LibXML'                  => 0,
    'XML::LibXML::XPathContext'    => 0,
);

WriteMakefile(
    NAME         => 'POE::Component::Amazon::S3',
    AUTHOR       => 'Andy Grundman <andy@hybridized.org>',
    LICENSE      => 'perl',
    VERSION_FROM => 'lib/POE/Component/Amazon/S3.pm',
    PREREQ_PM    => \%prereq,
    dist         => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
);
