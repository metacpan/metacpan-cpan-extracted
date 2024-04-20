#!perl
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
    'NAME'          => 'Net::EPP',
    'VERSION_FROM'  => 'lib/Net/EPP.pm',
    'ABSTRACT_FROM' => 'lib/Net/EPP.pm',
    'AUTHOR'        => ['Gavin Brown <gavin.brown@fastmail.uk>'],
    'LICENSE'       => 'perl',
    'PREREQ_PM'     => {
        'Digest::SHA'     => 0,
        'IO::Socket::SSL' => 0,
        'IO::Socket::IP'  => 0,
        'List::Util'      => 0,
        'Time::HiRes'     => 0,
        'XML::LibXML'     => 0,
    },
    'META_MERGE' => {
        'meta-spec' => {'version' => 2},
        'resources' => {
            'repository' => {
                'type' => 'git',
                'url'  => 'https://github.com/gbxyz/perl-net-epp.git',
                'web'  => 'https://github.com/gbxyz/perl-net-epp',
            },
            'bugtracker' => {
                'web' => 'https://github.com/gbxyz/perl-net-epp/issues',
            },
        },
    },
);
