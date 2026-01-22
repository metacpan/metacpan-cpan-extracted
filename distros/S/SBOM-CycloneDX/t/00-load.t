#!perl

use strict;
use warnings;

use Test::More;

my @modules = qw[
    SBOM::CycloneDX
    SBOM::CycloneDX::Advisory
    SBOM::CycloneDX::Annotation
    SBOM::CycloneDX::Annotation::Annotator
    SBOM::CycloneDX::Attachment
    SBOM::CycloneDX::Base
    SBOM::CycloneDX::BomRef
    SBOM::CycloneDX::Citation
    SBOM::CycloneDX::Component
    SBOM::CycloneDX::Component::Commit
    SBOM::CycloneDX::Component::ConfidenceInterval
    SBOM::CycloneDX::Component::Diff
    SBOM::CycloneDX::Component::Graphic
    SBOM::CycloneDX::Component::GraphicsCollection
    SBOM::CycloneDX::Component::ModelCard
    SBOM::CycloneDX::Component::Patch
    SBOM::CycloneDX::Component::Pedigree
    SBOM::CycloneDX::Component::PerformanceMetric
    SBOM::CycloneDX::Component::QuantitativeAnalysis
    SBOM::CycloneDX::Component::SWID
    SBOM::CycloneDX::CryptoProperties
    SBOM::CycloneDX::CryptoProperties::AlgorithmProperties
    SBOM::CycloneDX::CryptoProperties::CertificateExtension
    SBOM::CycloneDX::CryptoProperties::CertificateProperties
    SBOM::CycloneDX::CryptoProperties::CipherSuite
    SBOM::CycloneDX::CryptoProperties::Ikev2TransformType
    SBOM::CycloneDX::CryptoProperties::ProtocolProperties
    SBOM::CycloneDX::CryptoProperties::RelatedCryptographicAsset
    SBOM::CycloneDX::CryptoProperties::RelatedCryptoMaterialProperties
    SBOM::CycloneDX::CryptoProperties::SecuredBy
    SBOM::CycloneDX::DataGovernance
    SBOM::CycloneDX::DataGovernanceResponsibleParty
    SBOM::CycloneDX::Declarations
    SBOM::CycloneDX::Declarations::Affirmation
    SBOM::CycloneDX::Declarations::Assessor
    SBOM::CycloneDX::Declarations::Attestation
    SBOM::CycloneDX::Declarations::Claim
    SBOM::CycloneDX::Declarations::Confidence
    SBOM::CycloneDX::Declarations::Conformance
    SBOM::CycloneDX::Declarations::Contents
    SBOM::CycloneDX::Declarations::Data
    SBOM::CycloneDX::Declarations::Evidence
    SBOM::CycloneDX::Declarations::Map
    SBOM::CycloneDX::Declarations::Signatory
    SBOM::CycloneDX::Declarations::Targets
    SBOM::CycloneDX::Definitions
    SBOM::CycloneDX::Dependency
    SBOM::CycloneDX::Enum
    SBOM::CycloneDX::Enum::CommonExtensionName
    SBOM::CycloneDX::Enum::ComponentType
    SBOM::CycloneDX::Enum::CryptoAssetType
    SBOM::CycloneDX::Enum::CryptoCertificationLevel
    SBOM::CycloneDX::Enum::CryptoFunction
    SBOM::CycloneDX::Enum::CryptoImplementationPlatform
    SBOM::CycloneDX::Enum::CryptoMode
    SBOM::CycloneDX::Enum::CryptoPadding
    SBOM::CycloneDX::Enum::CryptoPrimitive
    SBOM::CycloneDX::Enum::ExternalReferenceType
    SBOM::CycloneDX::Enum::ImpactAnalysisJustification
    SBOM::CycloneDX::Enum::ImpactAnalysisState
    SBOM::CycloneDX::Enum::HashAlgorithm
    SBOM::CycloneDX::Enum::LicenseType
    SBOM::CycloneDX::Enum::LifecyclePhase
    SBOM::CycloneDX::Enum::PatentAssertionType
    SBOM::CycloneDX::Enum::PatentLegalStatus
    SBOM::CycloneDX::Enum::ProtocolType
    SBOM::CycloneDX::Enum::RelatedCryptoMaterialState
    SBOM::CycloneDX::Enum::RelatedCryptoMaterialType
    SBOM::CycloneDX::Enum::TlpClassification
    SBOM::CycloneDX::ExternalReference
    SBOM::CycloneDX::Formulation
    SBOM::CycloneDX::Hash
    SBOM::CycloneDX::IdentifiableAction
    SBOM::CycloneDX::Issue
    SBOM::CycloneDX::Issue::Source
    SBOM::CycloneDX::License
    SBOM::CycloneDX::License::ExpressionDetail
    SBOM::CycloneDX::License::Licensee
    SBOM::CycloneDX::License::Licensing
    SBOM::CycloneDX::License::Licensor
    SBOM::CycloneDX::License::Purchaser
    SBOM::CycloneDX::List
    SBOM::CycloneDX::Lite
    SBOM::CycloneDX::Metadata
    SBOM::CycloneDX::Metadata::DistributionConstraint
    SBOM::CycloneDX::Metadata::Lifecycle
    SBOM::CycloneDX::Note
    SBOM::CycloneDX::OrganizationalContact
    SBOM::CycloneDX::OrganizationalEntity
    SBOM::CycloneDX::Patent
    SBOM::CycloneDX::Patent::PriorityApplication
    SBOM::CycloneDX::PatentAssertion
    SBOM::CycloneDX::PatentFamily
    SBOM::CycloneDX::PostalAddress
    SBOM::CycloneDX::Property
    SBOM::CycloneDX::ReleaseNotes
    SBOM::CycloneDX::Schema
    SBOM::CycloneDX::Service
    SBOM::CycloneDX::Standard
    SBOM::CycloneDX::Standard::Level
    SBOM::CycloneDX::Standard::Requirement
    SBOM::CycloneDX::Timestamp
    SBOM::CycloneDX::Tool
    SBOM::CycloneDX::Tools
    SBOM::CycloneDX::Util
    SBOM::CycloneDX::Version
    SBOM::CycloneDX::Vulnerability
    SBOM::CycloneDX::Vulnerability::Affect
    SBOM::CycloneDX::Vulnerability::Analysis
    SBOM::CycloneDX::Vulnerability::Credits
    SBOM::CycloneDX::Vulnerability::ProofOfConcept
    SBOM::CycloneDX::Vulnerability::Rating
    SBOM::CycloneDX::Vulnerability::Reference
    SBOM::CycloneDX::Vulnerability::Source
];

for my $module (@modules) {
    use_ok $module or BAIL_OUT "Can't load $module";
}

diag("SBOM::CycloneDX $SBOM::CycloneDX::VERSION, Perl $], $^X");

done_testing();
