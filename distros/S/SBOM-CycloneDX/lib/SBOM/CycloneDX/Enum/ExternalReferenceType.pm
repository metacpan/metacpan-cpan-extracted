package SBOM::CycloneDX::Enum::ExternalReferenceType;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        VCS                       => 'vcs',
        ISSUE_TRACKER             => 'issue-tracker',
        WEBSITE                   => 'website',
        ADVISORIES                => 'advisories',
        BOM                       => 'bom',
        MAILING_LIST              => 'mailing-list',
        SOCIAL                    => 'social',
        CHAT                      => 'chat',
        DOCUMENTATION             => 'documentation',
        SUPPORT                   => 'support',
        SOURCE_DISTRIBUTION       => 'source-distribution',
        DISTRIBUTION              => 'distribution',
        DISTRIBUTION_INTAKE       => 'distribution-intake',
        LICENSE                   => 'license',
        BUILD_META                => 'build-meta',
        BUILD_SYSTEM              => 'build-system',
        RELEASE_NOTES             => 'release-notes',
        SECURITY_CONTACT          => 'security-contact',
        MODEL_CARD                => 'model-card',
        LOG                       => 'log',
        CONFIGURATION             => 'configuration',
        EVIDENCE                  => 'evidence',
        FORMULATION               => 'formulation',
        ATTESTATION               => 'attestation',
        THREAT_MODEL              => 'threat-model',
        ADVERSARY_MODEL           => 'adversary-model',
        RISK_ASSESSMENT           => 'risk-assessment',
        VULNERABILITY_ASSERTION   => 'vulnerability-assertion',
        EXPLOITABILITY_STATEMENT  => 'exploitability-statement',
        PENTEST_REPORT            => 'pentest-report',
        STATIC_ANALYSIS_REPORT    => 'static-analysis-report',
        DYNAMIC_ANALYSIS_REPORT   => 'dynamic-analysis-report',
        RUNTIME_ANALYSIS_REPORT   => 'runtime-analysis-report',
        COMPONENT_ANALYSIS_REPORT => 'component-analysis-report',
        MATURITY_REPORT           => 'maturity-report',
        CERTIFICATION_REPORT      => 'certification-report',
        CODIFIED_INFRASTRUCTURE   => 'codified-infrastructure',
        QUALITY_METRICS           => 'quality-metrics',
        POAM                      => 'poam',
        ELECTRONIC_SIGNATURE      => 'electronic-signature',
        DIGITAL_SIGNATURE         => 'digital-signature',
        RFC_9116                  => 'rfc-9116',
        PATENT                    => 'patent',
        PATENT_FAMILY             => 'patent-family',
        PATENT_ASSERTION          => 'patent-assertion',
        CITATION                  => 'citation',
        OTHER                     => 'other',
    );

    require constant;
    constant->import(\%ENUM);

    @EXPORT_OK   = sort keys %ENUM;
    %EXPORT_TAGS = (all => \@EXPORT_OK);

}

sub values { sort values %ENUM }


1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Enum::ExternalReferenceType - External Reference Type

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(EXTERNAL_REFERENCE_TYPE);

    say EXTERNAL_REFERENCE_TYPE->ISSUE_TRACKER;


    use SBOM::CycloneDX::Enum::ExternalReferenceType;

    say SBOM::CycloneDX::Enum::ExternalReferenceType->DOCUMENTATION;


    use SBOM::CycloneDX::Enum::ExternalReferenceType qw(:all);

    say ADVISORIES;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::ExternalReferenceType> is ENUM package used by L<SBOM::CycloneDX::ExternalReference>.

Specifies the type of external reference.


=head1 CONSTANTS

=over

=item * C<VCS>, Version Control System

=item * C<ISSUE_TRACKER>, Issue or defect tracking system, or an
Application Lifecycle Management (ALM) system

=item * C<WEBSITE>, Website

=item * C<ADVISORIES>, Security advisories

=item * C<BOM>, Bill of Materials (SBOM, OBOM, HBOM, SaaSBOM, etc)

=item * C<MAILING_LIST>, Mailing list or discussion group

=item * C<SOCIAL>, Social media account

=item * C<CHAT>, Real-time chat platform

=item * C<DOCUMENTATION>, Documentation, guides, or how-to instructions

=item * C<SUPPORT>, Community or commercial support

=item * C<SOURCE_DISTRIBUTION>, The location where the source code
distributable can be obtained. This is often an archive format such as zip
or tgz. The source-distribution type complements use of the version control
(vcs) type.

=item * C<DISTRIBUTION>, Direct or repository download location

=item * C<DISTRIBUTION_INTAKE>, The location where a component was
published to. This is often the same as "distribution" but may also include
specialized publishing processes that act as an intermediary.

=item * C<LICENSE>, The reference to the license file. If a license URL has
been defined in the license node, it should also be defined as an external
reference for completeness.

=item * C<BUILD_META>, Build-system specific meta file (i.e. pom.xml,
package.json, .nuspec, etc)

=item * C<BUILD_SYSTEM>, Reference to an automated build system

=item * C<RELEASE_NOTES>, Reference to release notes

=item * C<SECURITY_CONTACT>, Specifies a way to contact the maintainer,
supplier, or provider in the event of a security incident. Common URIs
include links to a disclosure procedure, a mailto (RFC-2368) that specifies
an email address, a tel (RFC-3966) that specifies a phone number, or dns
(RFC-4501) that specifies the records containing DNS Security TXT.

=item * C<MODEL_CARD>, A model card describes the intended uses of a
machine learning model, potential limitations, biases, ethical
considerations, training parameters, datasets used to train the model,
performance metrics, and other relevant data useful for ML transparency.

=item * C<LOG>, A record of events that occurred in a computer system or
application, such as problems, errors, or information on current
operations.

=item * C<CONFIGURATION>, Parameters or settings that may be used by other
components or services.

=item * C<EVIDENCE>, Information used to substantiate a claim.

=item * C<FORMULATION>, Describes the formulation of any referencable
object within the BOM, including components, services, metadata,
declarations, or the BOM itself.

=item * C<ATTESTATION>, Human or machine-readable statements containing
facts, evidence, or testimony.

=item * C<THREAT_MODEL>, An enumeration of identified weaknesses, threats,
and countermeasures, dataflow diagram (DFD), attack tree, and other
supporting documentation in human-readable or machine-readable format.

=item * C<ADVERSARY_MODEL>, The defined assumptions, goals, and
capabilities of an adversary.

=item * C<RISK_ASSESSMENT>, Identifies and analyzes the potential of future
events that may negatively impact individuals, assets, and/or the
environment. Risk assessments may also include judgments on the
tolerability of each risk.

=item * C<VULNERABILITY_ASSERTION>, A Vulnerability Disclosure Report (VDR)
which asserts the known and previously unknown vulnerabilities that affect
a component, service, or product including the analysis and findings
describing the impact (or lack of impact) that the reported vulnerability
has on a component, service, or product.

=item * C<EXPLOITABILITY_STATEMENT>, A Vulnerability Exploitability
eXchange (VEX) which asserts the known vulnerabilities that do not affect a
product, product family, or organization, and optionally the ones that do.
The VEX should include the analysis and findings describing the impact (or
lack of impact) that the reported vulnerability has on the product, product
family, or organization.

=item * C<PENTEST_REPORT>, Results from an authorized simulated cyberattack
on a component or service, otherwise known as a penetration test.

=item * C<STATIC_ANALYSIS_REPORT>, SARIF or proprietary machine or
human-readable report for which static analysis has identified code
quality, security, and other potential issues with the source code.

=item * C<DYNAMIC_ANALYSIS_REPORT>, Dynamic analysis report that has
identified issues such as vulnerabilities and misconfigurations.

=item * C<RUNTIME_ANALYSIS_REPORT>, Report generated by analyzing the call
stack of a running application.

=item * C<COMPONENT_ANALYSIS_REPORT>, Report generated by Software
Composition Analysis (SCA), container analysis, or other forms of component
analysis.

=item * C<MATURITY_REPORT>, Report containing a formal assessment of an
organization, business unit, or team against a maturity model.

=item * C<CERTIFICATION_REPORT>, Industry, regulatory, or other
certification from an accredited (if applicable) certification body.

=item * C<CODIFIED_INFRASTRUCTURE>, Code or configuration that defines and
provisions virtualized infrastructure, commonly referred to as
Infrastructure as Code (IaC).

=item * C<QUALITY_METRICS>, Report or system in which quality metrics can
be obtained.

=item * C<POAM>, Plans of Action and Milestones (POA&M) complement an
"attestation" external reference. POA&M is defined by NIST as a "document
that identifies tasks needing to be accomplished. It details resources
required to accomplish the elements of the plan, any milestones in meeting
the tasks and scheduled completion dates for the milestones".

=item * C<ELECTRONIC_SIGNATURE>, An e-signature is commonly a scanned
representation of a written signature or a stylized script of the person's
name.

=item * C<DIGITAL_SIGNATURE>, A signature that leverages cryptography,
typically public/private key pairs, which provides strong authenticity
verification.

=item * C<RFC_9116>, Document that complies with L<RFC
9116|https://www.ietf.org/rfc/rfc9116.html> (A File Format to Aid in
Security Vulnerability Disclosure)

=item * C<PATENT>, References information about patents which may be
defined in human-readable documents or in machine-readable formats such as
CycloneDX or ST.96. For detailed patent information or to reference the
information provided directly by patent offices, it is recommended to
leverage standards from the World Intellectual Property Organization (WIPO)
such as L<ST.96|https://www.wipo.int/standards/en/st96>.

=item * C<PATENT_FAMILY>, References information about a patent family
which may be defined in human-readable documents or in machine-readable
formats such as CycloneDX or ST.96. A patent family is a group of related
patent applications or granted patents that cover the same or similar
invention. For detailed patent family information or to reference the
information provided directly by patent offices, it is recommended to
leverage standards from the World Intellectual Property Organization (WIPO)
such as L<ST.96|https://www.wipo.int/standards/en/st96>.

=item * C<PATENT_ASSERTION>, References assertions made regarding patents
associated with a component or service. Assertions distinguish between
ownership, licensing, and other relevant interactions with patents.

=item * C<CITATION>, A reference to external citations applicable to the
object identified by this BOM entry or the BOM itself. When used with a
BOM-Link, this allows offloading citations into a separate CycloneDX BOM.

=item * C<OTHER>, Use this if no other types accurately describe the
purpose of the external reference.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
