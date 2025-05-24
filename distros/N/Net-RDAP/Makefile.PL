#!/usr/bin/perl
use ExtUtils::MakeMaker;
use warnings;
use strict;

WriteMakefile(
    NAME            => 'Net::RDAP',
    VERSION_FROM    => 'lib/Net/RDAP.pm',
    ABSTRACT        => 'An interface to the Registration Data Access Protocol (RDAP).',
    AUTHOR          => ['Gavin Brown <gavin.brown@fastmail.uk>'],
    LICENSE         => 'freebsd',
    PREREQ_PM => {
        'DateTime::Tiny'            => 0,
        'Digest::SHA'               => 0,
        'File::Basename'            => 0,
        'File::Slurp'               => 0,
        'File::Spec'                => 0,
        'File::stat'                => 0,
        'HTTP::Date'                => 0,
        'HTTP::Request::Common'     => 0,
        'JSON'                      => 0,
        'LWP::Online'               => 0,
        'LWP::Protocol::https'      => 0,
        'LWP::UserAgent'            => 0,
        'List::Util'                => 0,
        'MIME::Type'                => 0,
        'Mozilla::CA'               => 0,
        'Net::ASN'                  => 0,
        'Net::DNS::Domain'          => 0,
        'Net::DNS::RR::DNSKEY'      => 0,
        'Net::DNS::RR::DS'          => 0,
        'Net::IP'                   => 0,
        'Test::More'                => 0,
        'URI'                       => 0,
        'XML::LibXML'               => 0,
    },
    TEST_REQUIRES => {
        'Carp::Always'              => 0,
    },
    META_MERGE => {
        'meta-spec' => {
            version => 2
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/gbxyz/perl-Net-RDAP.git',
                web  => 'https://github.com/gbxyz/perl-Net-RDAP',
            },
            bugtracker => {
                web => 'https://github.com/gbxyz/perl-Net-RDAP/issues',
            },
        },
    },
);
