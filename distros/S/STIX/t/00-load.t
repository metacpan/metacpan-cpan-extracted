#!perl

use strict;
use warnings;

use Test::More;

my @CLASSES = (
    'STIX',                                         'STIX::AttackPattern',
    'STIX::Campaign',                               'STIX::Common::Bundle',
    'STIX::Common::ExtensionDefinition',            'STIX::Common::ExternalReference',
    'STIX::Common::GranularMarking',                'STIX::Common::KillChainPhase',
    'STIX::Common::MarkingDefinition',              'STIX::Common::Timestamp',
    'STIX::CourseOfAction',                         'STIX::Grouping',
    'STIX::Identity',                               'STIX::Incident',
    'STIX::Indicator',                              'STIX::Infrastructure',
    'STIX::IntrusionSet',                           'STIX::Location',
    'STIX::Malware',                                'STIX::MalwareAnalysis',
    'STIX::Marking::TLP::Amber',                    'STIX::Marking::TLP::Green',
    'STIX::Marking::TLP::Red',                      'STIX::Marking::TLP::White',
    'STIX::Note',                                   'STIX::Observable::Artifact',
    'STIX::Observable::AutonomousSystem',           'STIX::Observable::Directory',
    'STIX::Observable::DomainName',                 'STIX::Observable::EmailAddr',
    'STIX::Observable::EmailMessage',               'STIX::Observable::Extension::Archive',
    'STIX::Observable::Extension::HTTPRequest',     'STIX::Observable::Extension::ICMP',
    'STIX::Observable::Extension::NTFS',            'STIX::Observable::Extension::PDF',
    'STIX::Observable::Extension::RasterImage',     'STIX::Observable::Extension::Socket',
    'STIX::Observable::Extension::TCP',             'STIX::Observable::Extension::UnixAccount',
    'STIX::Observable::Extension::WindowsProcess',  'STIX::Observable::Extension::WindowsService',
    'STIX::Observable::File',                       'STIX::Observable::IPv4Addr',
    'STIX::Observable::IPv6Addr',                   'STIX::Observable::MACAddr',
    'STIX::Observable::Mutex',                      'STIX::Observable::NetworkTraffic',
    'STIX::Observable::Process',                    'STIX::Observable::Software',
    'STIX::Observable::Type::AlternateDataStream',  'STIX::Observable::Type::EmailMIMEPart',
    'STIX::Observable::Type::WindowsRegistryValue', 'STIX::Observable::Type::X509V3Extensions',
    'STIX::Observable::URL',                        'STIX::Observable::UserAccount',
    'STIX::Observable::WindowsRegistryKey',         'STIX::Observable::X509Certificate',
    'STIX::ObservedData',                           'STIX::Opinion',
    'STIX::Relationship',                           'STIX::Report',
    'STIX::Sighting',                               'STIX::ThreatActor',
    'STIX::Tool',                                   'STIX::Vulnerability'
);

use_ok($_) for @CLASSES;

done_testing();

diag("STIX $STIX::VERSION, Perl $], $^X");
