package STIX;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter qw(import);


# STIX Domain Objects
use STIX::AttackPattern;
use STIX::Campaign;
use STIX::CourseOfAction;
use STIX::Grouping;
use STIX::Identity;
use STIX::Incident;
use STIX::Indicator;
use STIX::Infrastructure;
use STIX::IntrusionSet;
use STIX::Location;
use STIX::Malware;
use STIX::MalwareAnalysis;
use STIX::Note;
use STIX::ObservedData;
use STIX::Opinion;
use STIX::Report;
use STIX::ThreatActor;
use STIX::Tool;
use STIX::Vulnerability;

# STIX Cyber-observable Objects
use STIX::Observable::Artifact;
use STIX::Observable::AutonomousSystem;
use STIX::Observable::Directory;
use STIX::Observable::DomainName;
use STIX::Observable::EmailAddr;
use STIX::Observable::EmailMessage;
use STIX::Observable::File;
use STIX::Observable::IPv4Addr;
use STIX::Observable::IPv6Addr;
use STIX::Observable::MACAddr;
use STIX::Observable::Mutex;
use STIX::Observable::NetworkTraffic;
use STIX::Observable::Process;
use STIX::Observable::Software;
use STIX::Observable::URL;
use STIX::Observable::UserAccount;
use STIX::Observable::WindowsRegistryKey;
use STIX::Observable::X509Certificate;

## Types
use STIX::Observable::Type::AlternateDataStream;
use STIX::Observable::Type::EmailMIMEPart;
use STIX::Observable::Type::WindowsRegistryValue;
use STIX::Observable::Type::X509V3Extensions;

## Extensions
use STIX::Observable::Extension::Archive;
use STIX::Observable::Extension::HTTPRequest;
use STIX::Observable::Extension::ICMP;
use STIX::Observable::Extension::NTFS;
use STIX::Observable::Extension::PDF;
use STIX::Observable::Extension::RasterImage;
use STIX::Observable::Extension::Socket;
use STIX::Observable::Extension::TCP;
use STIX::Observable::Extension::UnixAccount;
use STIX::Observable::Extension::WindowsProcess;
use STIX::Observable::Extension::WindowsService;

# STIX Relationship Objects
use STIX::Relationship;
use STIX::Sighting;

# Common
use STIX::Common::Bundle;
use STIX::Common::ExtensionDefinition;
use STIX::Common::ExternalReference;
use STIX::Common::GranularMarking;
use STIX::Common::KillChainPhase;
use STIX::Common::MarkingDefinition;

# TLP - Traffic Light Protocol
use STIX::Marking::TLP::White;
use STIX::Marking::TLP::Green;
use STIX::Marking::TLP::Amber;
use STIX::Marking::TLP::Red;


my @SDO = (qw[
    attack_pattern
    campaign
    course_of_action
    grouping
    identity
    incident
    indicator
    infrastructure
    intrusion_set
    location
    malware
    malware_analysis
    note
    observed_data
    opinion
    report
    threat_actor
    tool
    vulnerability
]);

my @SCO = (qw[
    alternate_data_stream_type
    archive_ext
    artifact
    autonomous_system
    directory
    domain_name
    email_addr
    email_message
    email_mime_component_type
    file
    http_request_ext
    icmp_ext
    ipv4_addr
    ipv6_addr
    mac_addr
    mutex
    network_traffic
    ntfs_ext
    pdf_ext
    process
    raster_image_ext
    socket_ext
    software
    tcp_ext
    unix_account_ext
    url
    user_account
    windows_process_ext
    windows_registry_key
    windows_registry_value_type
    windows_service_ext
    x509_certificate
    x509_v3_extensions_type
]);

my @SRO = (qw[
    relationship
    sighting
]);

my @TLP = (qw[
    tlp_white
    tlp_green
    tlp_amber
    tlp_red
]);

my @COMMON = (qw[
    bundle
    extension_definition
    external_reference
    kill_chain_phase
    marking_definition
]);

our $VERSION = '1.01';
$VERSION =~ tr/_//d;    ## no critic

our %EXPORT_TAGS = (
    all    => [@COMMON, @SDO, @SRO, @SCO, @TLP],
    common => \@COMMON,
    sco    => \@SCO,
    sdo    => \@SDO,
    sro    => \@SRO,
    tlp    => \@TLP,
);


Exporter::export_ok_tags('all');
Exporter::export_ok_tags('common');
Exporter::export_ok_tags('sco');
Exporter::export_ok_tags('sdo');
Exporter::export_ok_tags('sro');
Exporter::export_ok_tags('tlp');


use constant SCO_NAMESPACE => '00abedb4-aa42-466c-9c01-fed23315a9b7';


# STIX Domain Objects
sub attack_pattern   { STIX::AttackPattern->new(@_) }
sub campaign         { STIX::Campaign->new(@_) }
sub course_of_action { STIX::CourseOfAction->new(@_) }
sub grouping         { STIX::Grouping->new(@_) }
sub identity         { STIX::Identity->new(@_) }
sub incident         { STIX::Incident->new(@_) }
sub indicator        { STIX::Indicator->new(@_) }
sub infrastructure   { STIX::Infrastructure->new(@_) }
sub intrusion_set    { STIX::IntrusionSet->new(@_) }
sub location         { STIX::Location->new(@_) }
sub malware          { STIX::Malware->new(@_) }
sub malware_analysis { STIX::MalwareAnalysis->new(@_) }
sub note             { STIX::Note->new(@_) }
sub observed_data    { STIX::ObservedData->new(@_) }
sub opinion          { STIX::Opinion->new(@_) }
sub report           { STIX::Report->new(@_) }
sub threat_actor     { STIX::ThreatActor->new(@_) }
sub tool             { STIX::Tool->new(@_) }
sub vulnerability    { STIX::Vulnerability->new(@_) }

# STIX Relationship Objects
sub relationship { STIX::Relationship->new(@_) }
sub sighting     { STIX::Sighting->new(@_) }

# STIX Common
sub bundle               { STIX::Common::Bundle->new(@_) }
sub extension_definition { STIX::Common::ExtensionDefinition->new(@_) }
sub external_reference   { STIX::Common::ExternalReference->new(@_) }
sub granular_marking     { STIX::Common::GranularMarking->new(@_) }
sub kill_chain_phase     { STIX::Common::KillChainPhase->new(@_) }
sub marking_definition   { STIX::Common::MarkingDefinition->new(@_) }

# STIX Cyber-observable Objects
sub artifact             { STIX::Observable::Artifact->new(@_) }
sub autonomous_system    { STIX::Observable::AutonomousSystem->new(@_) }
sub directory            { STIX::Observable::Directory->new(@_) }
sub domain_name          { STIX::Observable::DomainName->new(@_) }
sub email_addr           { STIX::Observable::EmailAddr->new(@_) }
sub email_message        { STIX::Observable::EmailMessage->new(@_) }
sub file                 { STIX::Observable::File->new(@_) }
sub ipv4_addr            { STIX::Observable::IPv4Addr->new(@_) }
sub ipv6_addr            { STIX::Observable::IPv6Addr->new(@_) }
sub mac_addr             { STIX::Observable::MACAddr->new(@_) }
sub mutex                { STIX::Observable::Mutex->new(@_) }
sub network_traffic      { STIX::Observable::NetworkTraffic->new(@_) }
sub process              { STIX::Observable::Process->new(@_) }
sub software             { STIX::Observable::Software->new(@_) }
sub url                  { STIX::Observable::URL->new(@_) }
sub user_account         { STIX::Observable::UserAccount->new(@_) }
sub windows_registry_key { STIX::Observable::WindowsRegistryKey->new(@_) }
sub x509_certificate     { STIX::Observable::X509Certificate->new(@_) }

## Types
sub alternate_data_stream_type  { STIX::Observable::Type::AlternateDataStream->new(@_) }
sub email_mime_part_type        { STIX::Observable::Type::EmailMIMEPart->new(@_) }
sub windows_registry_value_type { STIX::Observable::Type::WindowsRegistryValue->new(@_) }
sub x509_v3_extensions_type     { STIX::Observable::Type::X509V3Extensions->new(@_) }

## Extensions
sub archive_ext         { STIX::Observable::Extension::Archive->new(@_) }
sub http_request_ext    { STIX::Observable::Extension::HTTPRequest->new(@_) }
sub icmp_ext            { STIX::Observable::Extension::ICMP->new(@_) }
sub ntfs_ext            { STIX::Observable::Extension::NTFS->new(@_) }
sub pdf_ext             { STIX::Observable::Extension::PDF->new(@_) }
sub raster_image_ext    { STIX::Observable::Extension::RasterImage->new(@_) }
sub socket_ext          { STIX::Observable::Extension::Socket->new(@_) }
sub tcp_ext             { STIX::Observable::Extension::TCP->new(@_) }
sub unix_account_ext    { STIX::Observable::Extension::UnixAccount->new(@_) }
sub windows_process_ext { STIX::Observable::Extension::WindowsProcess->new(@_) }
sub windows_service_ext { STIX::Observable::Extension::WindowsService->new(@_) }

# TLP
sub tlp_white { STIX::Marking::TLP::White->new(@_) }
sub tlp_green { STIX::Marking::TLP::Green->new(@_) }
sub tlp_amber { STIX::Marking::TLP::Amber->new(@_) }
sub tlp_red   { STIX::Marking::TLP::Red->new(@_) }


1;

=encoding utf-8

=head1 NAME

STIX - Structured Threat Information Expression (STIX)

=head1 SYNOPSIS

    # Object-Oriented interface

    use STIX::Indicator;
    use STIX::Common::Timestamp;
    use STIX::Common::Bundle;

    my $bundle = STIX::Common::Bundle->new;

    push @{ $bundle->objects }, STIX::Indicator->new(
        pattern_type    => 'stix',
        created         => STIX::Common::Timestamp->new('2014-05-08T09:00:00'),
        name            => 'IP Address for known C2 channel',
        description     => 'Test description C2 channel.',
        indicator_types => ['malicious-activity'],
        pattern         => "[ipv4-addr:value = '10.0.0.0']",
        valid_from      => STIX::Common::Timestamp->new('2014-05-08T09:00:00'),
    );

    # Functional interface

    use STIX qw(:all);

    my $bundle = bundle(
        objects => [
          indicator(
            pattern_type    => 'stix',
            created         => '2014-05-08T09:00:00',
            name            => 'IP Address for known C2 channel',
            description     => 'Test description C2 channel.',
            indicator_types => ['malicious-activity'],
            pattern         => "[ipv4-addr:value = '10.0.0.0']",
            valid_from      => '2014-05-08T09:00:00',
          )
        ]
    );


=head1 DESCRIPTION

Structured Threat Information Expression (STIX) is a language for expressing
cyber threat and observable information.

L<https://docs.oasis-open.org/cti/stix/v2.1/os/stix-v2.1-os.html>


=head2 Tags

=over

=item :all

Import all STIX objects

=item :common

Import all common objects

=item :sco

Import all STIX Cyber-observable Objects

=item :sdo

Import all STIX Domain Objects

=item :sro

Import all STIX Relationship Objects

=item :tlp

Import TLP (Traffic Light Protocol) statement marking

=back


=head2 STIX Domain Objects

STIX defines a set of STIX Domain Objects (SDOs): Attack Pattern, Campaign,
Course of Action, Grouping, Identity, Indicator, Infrastructure, Intrusion
Set, Location, Malware, Malware Analysis, Note, Observed Data, Opinion,
Report, Threat Actor, Tool, and Vulnerability. Each of these objects
corresponds to a concept commonly used in CTI.

=over

=item attack_pattern

Return L<STIX::AttackPattern> object.

=item campaign

Return L<STIX::Campaign> object.

=item course_of_action

Return L<STIX::CourseOfAction> object.

=item grouping

Return L<STIX::Grouping> object.

=item identity

Return L<STIX::Identity> object.

=item incident

Return L<STIX::Incident> object.

=item indicator

Return L<STIX::Indicator> object.

=item infrastructure

Return L<STIX::Infrastructure> object.

=item intrusion_set

Return L<STIX::IntrusionSet> object.

=item location

Return L<STIX::Location> object.

=item malware

Return L<STIX::Malware> object.

=item malware_analysis

Return L<STIX::MalwareAnalysis> object.

=item note

Return L<STIX::Note> object.

=item observed_data

Return L<STIX::ObservedData> object.

=item opinion

Return L<STIX::Opinion> object.

=item report

Return L<STIX::Report> object.

=item threat_actor

Return L<STIX::ThreatActor> object.

=item tool

Return L<STIX::Tool> object.

=item vulnerability

Return L<STIX::Vulnerability> object.

=back


=head2 STIX Cyber-observable Objects

STIX defines a set of STIX Cyber-observable Objects (SCOs) for
characterizing host-based and network-based information. SCOs are used by
various STIX Domain Objects (SDOs) to provide supporting context. The
Observed Data SDO, for example, indicates that the raw data was observed at
a particular time.

STIX Cyber-observable Objects (SCOs) document the facts concerning what
happened on a network or host, and do not capture the who, when, or why. By
associating SCOs with STIX Domain Objects (SDOs), it is possible to convey
a higher-level understanding of the threat landscape, and to potentially
provide insight as to the who and the why particular intelligence may be
relevant to an organization. For example, information about a file that
existed, a process that was observed running, or that network traffic
occurred between two IPs can all be captured as SCOs.

=over

=item artifact

Return L<STIX::Observable::Artifact> object.

=item autonomous_system

Return L<STIX::Observable::AutonomousSystem> object.

=item directory

Return L<STIX::Observable::Directory> object.

=item domain_name

Return L<STIX::Observable::DomainName> object.

=item email_addr

Return L<STIX::Observable::EmailAddr> object.

=item email_message

Return L<STIX::Observable::EmailMessage> object.

=item file

Return L<STIX::Observable::File> object.

=item ipv4_addr

Return L<STIX::Observable::IPv4Addr> object.

=item ipv6_addr

Return L<STIX::Observable::IPv6Addr> object.

=item mac_addr

Return L<STIX::Observable::MACAddr> object.

=item mutex

Return L<STIX::Observable::Mutex> object.

=item network_traffic

Return L<STIX::Observable::NetworkTraffic> object.

=item process

Return L<STIX::Observable::Process> object.

=item software

Return L<STIX::Observable::Software> object.

=item url

Return L<STIX::Observable::URL> object.

=item user_account

Return L<STIX::Observable::UserAccount> object.

=item windows_registry_key

Return L<STIX::Observable::WindowsRegistryKey> object.

=item x509_certificate

Return L<STIX::Observable::X509Certificate> object.

=back


=head3 Types

=over

=item alternate_data_stream_type

Return L<STIX::Observable::Type::AlternateDataStream> object.

=item email_mime_part_type

Return L<STIX::Observable::Type::EmailMIMEPart> object.

=item windows_registry_value_type

Return L<STIX::Observable::Type::WindowsRegistryValue> object.

=item x509_v3_extensions_type

Return L<STIX::Observable::Type::X509V3Extensions> object.

=back


=head3 Extensions

=over

=item archive_ext

Return L<STIX::Observable::Extension::Archive> object.

=item http_request_ext

Return L<STIX::Observable::Extension::HTTPRequest> object.

=item icmp_ext

Return L<STIX::Observable::Extension::ICMP> object.

=item ntfs_ext

Return L<STIX::Observable::Extension::NTFS> object.

=item pdf_ext

Return L<STIX::Observable::Extension::PDF> object.

=item raster_image_ext

Return L<STIX::Observable::Extension::RasterImage> object.

=item socket_ext

Return L<STIX::Observable::Extension::Socket> object.

=item tcp_ext

Return L<STIX::Observable::Extension::TCP> object.

=item unix_account_ext

Return L<STIX::Observable::Extension::UnixAccount> object.

=item windows_process_ext

Return L<STIX::Observable::Extension::WindowsProcess> object.

=item windows_service_ext

Return L<STIX::Observable::Extension::WindowsService> object.

=back


=head2 STIX Relationship Objects

A relationship is a link between STIX Domain Objects (SDOs), STIX
Cyber-observable Objects (SCOs), or between an SDO and a SCO that describes
the way in which the objects are related. Relationships can be represented
using an external STIX Relationship Object (SRO) or, in some cases, through
certain properties which store an identifier reference that comprises an
embedded relationship.

=over

=item relationship

Return L<STIX::Relationship> object.

=item sighting

Return L<STIX::Sighting> object.

=back


=head2 Common Objects

STIX Domain Objects (SDOs) and Relationship Objects (SROs) all share a
common set of properties which provide core capabilities such as versioning
and data markings (representing how data can be shared and used). All STIX
Cyber-observable Objects (SCOs) likewise share a common set of properties
that are applicable for all SCOs. Similarly, STIX Meta Objects (SMOs) use
some but not all of the common properties.

=over

=item bundle

Return L<STIX::Common::Bundle> object.

=item extension_definition

Return L<STIX::Common::ExtensionDefinition> object.

=item external_reference

Return L<STIX::Common::ExternalReference> object.

=item granular_marking

Return L<STIX::Common::GranularMarking> object.

=item kill_chain_phase

Return L<STIX::Common::KillChainPhase> object.

=item marking_definition

Return L<STIX::Common::MarkingDefinition> object.

=back


=head3 TLP

=over

=item tlp_white

Return L<STIX::Marking::TLP::White> object.

=item tlp_green

Return L<STIX::Marking::TLP::Green> object.

=item tlp_amber

Return L<STIX::Marking::TLP::Amber> object.

=item tlp_red

Return L<STIX::Marking::TLP::Red> object.

=back



=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
