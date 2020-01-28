use utf8;

package SemanticWeb::Schema::HealthInsurancePlan;

# ABSTRACT: A US-style health insurance plan

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'HealthInsurancePlan';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.0';


has benefits_summary_url => (
    is        => 'rw',
    predicate => '_has_benefits_summary_url',
    json_ld   => 'benefitsSummaryUrl',
);



has contact_point => (
    is        => 'rw',
    predicate => '_has_contact_point',
    json_ld   => 'contactPoint',
);



has health_plan_drug_option => (
    is        => 'rw',
    predicate => '_has_health_plan_drug_option',
    json_ld   => 'healthPlanDrugOption',
);



has health_plan_drug_tier => (
    is        => 'rw',
    predicate => '_has_health_plan_drug_tier',
    json_ld   => 'healthPlanDrugTier',
);



has health_plan_id => (
    is        => 'rw',
    predicate => '_has_health_plan_id',
    json_ld   => 'healthPlanId',
);



has health_plan_marketing_url => (
    is        => 'rw',
    predicate => '_has_health_plan_marketing_url',
    json_ld   => 'healthPlanMarketingUrl',
);



has includes_health_plan_formulary => (
    is        => 'rw',
    predicate => '_has_includes_health_plan_formulary',
    json_ld   => 'includesHealthPlanFormulary',
);



has includes_health_plan_network => (
    is        => 'rw',
    predicate => '_has_includes_health_plan_network',
    json_ld   => 'includesHealthPlanNetwork',
);



has uses_health_plan_id_standard => (
    is        => 'rw',
    predicate => '_has_uses_health_plan_id_standard',
    json_ld   => 'usesHealthPlanIdStandard',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HealthInsurancePlan - A US-style health insurance plan

=head1 VERSION

version v6.0.0

=head1 DESCRIPTION

A US-style health insurance plan, including PPOs, EPOs, and HMOs.

=head1 ATTRIBUTES

=head2 C<benefits_summary_url>

C<benefitsSummaryUrl>

The URL that goes directly to the summary of benefits and coverage for the
specific standard plan or plan variation.

A benefits_summary_url should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_benefits_summary_url>

A predicate for the L</benefits_summary_url> attribute.

=head2 C<contact_point>

C<contactPoint>

A contact point for a person or organization.

A contact_point should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ContactPoint']>

=back

=head2 C<_has_contact_point>

A predicate for the L</contact_point> attribute.

=head2 C<health_plan_drug_option>

C<healthPlanDrugOption>

TODO.

A health_plan_drug_option should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_drug_option>

A predicate for the L</health_plan_drug_option> attribute.

=head2 C<health_plan_drug_tier>

C<healthPlanDrugTier>

The tier(s) of drugs offered by this formulary or insurance plan.

A health_plan_drug_tier should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_drug_tier>

A predicate for the L</health_plan_drug_tier> attribute.

=head2 C<health_plan_id>

C<healthPlanId>

The 14-character, HIOS-generated Plan ID number. (Plan IDs must be unique,
even across different markets.)

A health_plan_id should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_id>

A predicate for the L</health_plan_id> attribute.

=head2 C<health_plan_marketing_url>

C<healthPlanMarketingUrl>

The URL that goes directly to the plan brochure for the specific standard
plan or plan variation.

A health_plan_marketing_url should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_marketing_url>

A predicate for the L</health_plan_marketing_url> attribute.

=head2 C<includes_health_plan_formulary>

C<includesHealthPlanFormulary>

Formularies covered by this plan.

A includes_health_plan_formulary should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::HealthPlanFormulary']>

=back

=head2 C<_has_includes_health_plan_formulary>

A predicate for the L</includes_health_plan_formulary> attribute.

=head2 C<includes_health_plan_network>

C<includesHealthPlanNetwork>

Networks covered by this plan.

A includes_health_plan_network should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::HealthPlanNetwork']>

=back

=head2 C<_has_includes_health_plan_network>

A predicate for the L</includes_health_plan_network> attribute.

=head2 C<uses_health_plan_id_standard>

C<usesHealthPlanIdStandard>

The standard for interpreting thePlan ID. The preferred is "HIOS". See the
Centers for Medicare &amp; Medicaid Services for more details.

A uses_health_plan_id_standard should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_uses_health_plan_id_standard>

A predicate for the L</uses_health_plan_id_standard> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/SemanticWeb-Schema>
and may be cloned from L<git://github.com/robrwo/SemanticWeb-Schema.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/SemanticWeb-Schema/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2020 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
