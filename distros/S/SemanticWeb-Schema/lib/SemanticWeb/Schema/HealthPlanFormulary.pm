use utf8;

package SemanticWeb::Schema::HealthPlanFormulary;

# ABSTRACT: For a given health insurance plan

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'HealthPlanFormulary';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has health_plan_cost_sharing => (
    is        => 'rw',
    predicate => '_has_health_plan_cost_sharing',
    json_ld   => 'healthPlanCostSharing',
);



has health_plan_drug_tier => (
    is        => 'rw',
    predicate => '_has_health_plan_drug_tier',
    json_ld   => 'healthPlanDrugTier',
);



has offers_prescription_by_mail => (
    is        => 'rw',
    predicate => '_has_offers_prescription_by_mail',
    json_ld   => 'offersPrescriptionByMail',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HealthPlanFormulary - For a given health insurance plan

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

For a given health insurance plan, the specification for costs and coverage
of prescription drugs.

=head1 ATTRIBUTES

=head2 C<health_plan_cost_sharing>

C<healthPlanCostSharing>

Whether The costs to the patient for services under this network or
formulary.

A health_plan_cost_sharing should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_health_plan_cost_sharing>

A predicate for the L</health_plan_cost_sharing> attribute.

=head2 C<health_plan_drug_tier>

C<healthPlanDrugTier>

The tier(s) of drugs offered by this formulary or insurance plan.

A health_plan_drug_tier should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_health_plan_drug_tier>

A predicate for the L</health_plan_drug_tier> attribute.

=head2 C<offers_prescription_by_mail>

C<offersPrescriptionByMail>

Whether prescriptions can be delivered by mail.

A offers_prescription_by_mail should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_offers_prescription_by_mail>

A predicate for the L</offers_prescription_by_mail> attribute.

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
