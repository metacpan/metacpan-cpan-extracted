use utf8;

package SemanticWeb::Schema::Drug;

# ABSTRACT: A chemical or biologic substance

use Moo;

extends qw/ SemanticWeb::Schema::Substance /;


use MooX::JSON_LD 'Drug';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has active_ingredient => (
    is        => 'rw',
    predicate => '_has_active_ingredient',
    json_ld   => 'activeIngredient',
);



has administration_route => (
    is        => 'rw',
    predicate => '_has_administration_route',
    json_ld   => 'administrationRoute',
);



has alcohol_warning => (
    is        => 'rw',
    predicate => '_has_alcohol_warning',
    json_ld   => 'alcoholWarning',
);



has available_strength => (
    is        => 'rw',
    predicate => '_has_available_strength',
    json_ld   => 'availableStrength',
);



has breastfeeding_warning => (
    is        => 'rw',
    predicate => '_has_breastfeeding_warning',
    json_ld   => 'breastfeedingWarning',
);



has clincal_pharmacology => (
    is        => 'rw',
    predicate => '_has_clincal_pharmacology',
    json_ld   => 'clincalPharmacology',
);



has clinical_pharmacology => (
    is        => 'rw',
    predicate => '_has_clinical_pharmacology',
    json_ld   => 'clinicalPharmacology',
);



has cost => (
    is        => 'rw',
    predicate => '_has_cost',
    json_ld   => 'cost',
);



has dosage_form => (
    is        => 'rw',
    predicate => '_has_dosage_form',
    json_ld   => 'dosageForm',
);



has dose_schedule => (
    is        => 'rw',
    predicate => '_has_dose_schedule',
    json_ld   => 'doseSchedule',
);



has drug_class => (
    is        => 'rw',
    predicate => '_has_drug_class',
    json_ld   => 'drugClass',
);



has drug_unit => (
    is        => 'rw',
    predicate => '_has_drug_unit',
    json_ld   => 'drugUnit',
);



has food_warning => (
    is        => 'rw',
    predicate => '_has_food_warning',
    json_ld   => 'foodWarning',
);



has included_in_health_insurance_plan => (
    is        => 'rw',
    predicate => '_has_included_in_health_insurance_plan',
    json_ld   => 'includedInHealthInsurancePlan',
);



has interacting_drug => (
    is        => 'rw',
    predicate => '_has_interacting_drug',
    json_ld   => 'interactingDrug',
);



has is_available_generically => (
    is        => 'rw',
    predicate => '_has_is_available_generically',
    json_ld   => 'isAvailableGenerically',
);



has is_proprietary => (
    is        => 'rw',
    predicate => '_has_is_proprietary',
    json_ld   => 'isProprietary',
);



has label_details => (
    is        => 'rw',
    predicate => '_has_label_details',
    json_ld   => 'labelDetails',
);



has legal_status => (
    is        => 'rw',
    predicate => '_has_legal_status',
    json_ld   => 'legalStatus',
);



has manufacturer => (
    is        => 'rw',
    predicate => '_has_manufacturer',
    json_ld   => 'manufacturer',
);



has maximum_intake => (
    is        => 'rw',
    predicate => '_has_maximum_intake',
    json_ld   => 'maximumIntake',
);



has mechanism_of_action => (
    is        => 'rw',
    predicate => '_has_mechanism_of_action',
    json_ld   => 'mechanismOfAction',
);



has non_proprietary_name => (
    is        => 'rw',
    predicate => '_has_non_proprietary_name',
    json_ld   => 'nonProprietaryName',
);



has overdosage => (
    is        => 'rw',
    predicate => '_has_overdosage',
    json_ld   => 'overdosage',
);



has pregnancy_category => (
    is        => 'rw',
    predicate => '_has_pregnancy_category',
    json_ld   => 'pregnancyCategory',
);



has pregnancy_warning => (
    is        => 'rw',
    predicate => '_has_pregnancy_warning',
    json_ld   => 'pregnancyWarning',
);



has prescribing_info => (
    is        => 'rw',
    predicate => '_has_prescribing_info',
    json_ld   => 'prescribingInfo',
);



has prescription_status => (
    is        => 'rw',
    predicate => '_has_prescription_status',
    json_ld   => 'prescriptionStatus',
);



has proprietary_name => (
    is        => 'rw',
    predicate => '_has_proprietary_name',
    json_ld   => 'proprietaryName',
);



has related_drug => (
    is        => 'rw',
    predicate => '_has_related_drug',
    json_ld   => 'relatedDrug',
);



has rxcui => (
    is        => 'rw',
    predicate => '_has_rxcui',
    json_ld   => 'rxcui',
);



has warning => (
    is        => 'rw',
    predicate => '_has_warning',
    json_ld   => 'warning',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Drug - A chemical or biologic substance

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

A chemical or biologic substance, used as a medical therapy, that has a
physiological effect on an organism. Here the term drug is used
interchangeably with the term medicine although clinical knowledge make a
clear difference between them.

=head1 ATTRIBUTES

=head2 C<active_ingredient>

C<activeIngredient>

An active ingredient, typically chemical compounds and/or biologic
substances.

A active_ingredient should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_active_ingredient>

A predicate for the L</active_ingredient> attribute.

=head2 C<administration_route>

C<administrationRoute>

A route by which this drug may be administered, e.g. 'oral'.

A administration_route should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_administration_route>

A predicate for the L</administration_route> attribute.

=head2 C<alcohol_warning>

C<alcoholWarning>

Any precaution, guidance, contraindication, etc. related to consumption of
alcohol while taking this drug.

A alcohol_warning should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_alcohol_warning>

A predicate for the L</alcohol_warning> attribute.

=head2 C<available_strength>

C<availableStrength>

An available dosage strength for the drug.

A available_strength should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DrugStrength']>

=back

=head2 C<_has_available_strength>

A predicate for the L</available_strength> attribute.

=head2 C<breastfeeding_warning>

C<breastfeedingWarning>

Any precaution, guidance, contraindication, etc. related to this drug's use
by breastfeeding mothers.

A breastfeeding_warning should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_breastfeeding_warning>

A predicate for the L</breastfeeding_warning> attribute.

=head2 C<clincal_pharmacology>

C<clincalPharmacology>

Description of the absorption and elimination of drugs, including their
concentration (pharmacokinetics, pK) and biological effects
(pharmacodynamics, pD).

A clincal_pharmacology should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_clincal_pharmacology>

A predicate for the L</clincal_pharmacology> attribute.

=head2 C<clinical_pharmacology>

C<clinicalPharmacology>

Description of the absorption and elimination of drugs, including their
concentration (pharmacokinetics, pK) and biological effects
(pharmacodynamics, pD).

A clinical_pharmacology should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_clinical_pharmacology>

A predicate for the L</clinical_pharmacology> attribute.

=head2 C<cost>

Cost per unit of the drug, as reported by the source being tagged.

A cost should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DrugCost']>

=back

=head2 C<_has_cost>

A predicate for the L</cost> attribute.

=head2 C<dosage_form>

C<dosageForm>

A dosage form in which this drug/supplement is available, e.g. 'tablet',
'suspension', 'injection'.

A dosage_form should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_dosage_form>

A predicate for the L</dosage_form> attribute.

=head2 C<dose_schedule>

C<doseSchedule>

A dosing schedule for the drug for a given population, either observed,
recommended, or maximum dose based on the type used.

A dose_schedule should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DoseSchedule']>

=back

=head2 C<_has_dose_schedule>

A predicate for the L</dose_schedule> attribute.

=head2 C<drug_class>

C<drugClass>

The class of drug this belongs to (e.g., statins).

A drug_class should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DrugClass']>

=back

=head2 C<_has_drug_class>

A predicate for the L</drug_class> attribute.

=head2 C<drug_unit>

C<drugUnit>

The unit in which the drug is measured, e.g. '5 mg tablet'.

A drug_unit should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_drug_unit>

A predicate for the L</drug_unit> attribute.

=head2 C<food_warning>

C<foodWarning>

Any precaution, guidance, contraindication, etc. related to consumption of
specific foods while taking this drug.

A food_warning should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_food_warning>

A predicate for the L</food_warning> attribute.

=head2 C<included_in_health_insurance_plan>

C<includedInHealthInsurancePlan>

The insurance plans that cover this drug.

A included_in_health_insurance_plan should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::HealthInsurancePlan']>

=back

=head2 C<_has_included_in_health_insurance_plan>

A predicate for the L</included_in_health_insurance_plan> attribute.

=head2 C<interacting_drug>

C<interactingDrug>

Another drug that is known to interact with this drug in a way that impacts
the effect of this drug or causes a risk to the patient. Note: disease
interactions are typically captured as contraindications.

A interacting_drug should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Drug']>

=back

=head2 C<_has_interacting_drug>

A predicate for the L</interacting_drug> attribute.

=head2 C<is_available_generically>

C<isAvailableGenerically>

True if the drug is available in a generic form (regardless of name).

A is_available_generically should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_is_available_generically>

A predicate for the L</is_available_generically> attribute.

=head2 C<is_proprietary>

C<isProprietary>

True if this item's name is a proprietary/brand name (vs. generic name).

A is_proprietary should be one of the following types:

=over

=item C<Bool>

=back

=head2 C<_has_is_proprietary>

A predicate for the L</is_proprietary> attribute.

=head2 C<label_details>

C<labelDetails>

Link to the drug's label details.

A label_details should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_label_details>

A predicate for the L</label_details> attribute.

=head2 C<legal_status>

C<legalStatus>

The drug or supplement's legal status, including any controlled substance
schedules that apply.

A legal_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DrugLegalStatus']>

=item C<InstanceOf['SemanticWeb::Schema::MedicalEnumeration']>

=item C<Str>

=back

=head2 C<_has_legal_status>

A predicate for the L</legal_status> attribute.

=head2 C<manufacturer>

The manufacturer of the product.

A manufacturer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<_has_manufacturer>

A predicate for the L</manufacturer> attribute.

=head2 C<maximum_intake>

C<maximumIntake>

Recommended intake of this supplement for a given population as defined by
a specific recommending authority.

A maximum_intake should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MaximumDoseSchedule']>

=back

=head2 C<_has_maximum_intake>

A predicate for the L</maximum_intake> attribute.

=head2 C<mechanism_of_action>

C<mechanismOfAction>

The specific biochemical interaction through which this drug or supplement
produces its pharmacological effect.

A mechanism_of_action should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_mechanism_of_action>

A predicate for the L</mechanism_of_action> attribute.

=head2 C<non_proprietary_name>

C<nonProprietaryName>

The generic name of this drug or supplement.

A non_proprietary_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_non_proprietary_name>

A predicate for the L</non_proprietary_name> attribute.

=head2 C<overdosage>

Any information related to overdose on a drug, including signs or symptoms,
treatments, contact information for emergency response.

A overdosage should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_overdosage>

A predicate for the L</overdosage> attribute.

=head2 C<pregnancy_category>

C<pregnancyCategory>

Pregnancy category of this drug.

A pregnancy_category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DrugPregnancyCategory']>

=back

=head2 C<_has_pregnancy_category>

A predicate for the L</pregnancy_category> attribute.

=head2 C<pregnancy_warning>

C<pregnancyWarning>

Any precaution, guidance, contraindication, etc. related to this drug's use
during pregnancy.

A pregnancy_warning should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_pregnancy_warning>

A predicate for the L</pregnancy_warning> attribute.

=head2 C<prescribing_info>

C<prescribingInfo>

Link to prescribing information for the drug.

A prescribing_info should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_prescribing_info>

A predicate for the L</prescribing_info> attribute.

=head2 C<prescription_status>

C<prescriptionStatus>

Indicates the status of drug prescription eg. local catalogs
classifications or whether the drug is available by prescription or
over-the-counter, etc.

A prescription_status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DrugPrescriptionStatus']>

=item C<Str>

=back

=head2 C<_has_prescription_status>

A predicate for the L</prescription_status> attribute.

=head2 C<proprietary_name>

C<proprietaryName>

Proprietary name given to the diet plan, typically by its originator or
creator.

A proprietary_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_proprietary_name>

A predicate for the L</proprietary_name> attribute.

=head2 C<related_drug>

C<relatedDrug>

Any other drug related to this one, for example commonly-prescribed
alternatives.

A related_drug should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Drug']>

=back

=head2 C<_has_related_drug>

A predicate for the L</related_drug> attribute.

=head2 C<rxcui>

The RxCUI drug identifier from RXNORM.

A rxcui should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_rxcui>

A predicate for the L</rxcui> attribute.

=head2 C<warning>

Any FDA or other warnings about the drug (text or URL).

A warning should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_warning>

A predicate for the L</warning> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Substance>

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
