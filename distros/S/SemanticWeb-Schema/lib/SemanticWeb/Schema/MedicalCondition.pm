use utf8;

package SemanticWeb::Schema::MedicalCondition;

# ABSTRACT: Any condition of the human body that affects the normal functioning of a person

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalCondition';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has associated_anatomy => (
    is        => 'rw',
    predicate => '_has_associated_anatomy',
    json_ld   => 'associatedAnatomy',
);



has differential_diagnosis => (
    is        => 'rw',
    predicate => '_has_differential_diagnosis',
    json_ld   => 'differentialDiagnosis',
);



has drug => (
    is        => 'rw',
    predicate => '_has_drug',
    json_ld   => 'drug',
);



has epidemiology => (
    is        => 'rw',
    predicate => '_has_epidemiology',
    json_ld   => 'epidemiology',
);



has expected_prognosis => (
    is        => 'rw',
    predicate => '_has_expected_prognosis',
    json_ld   => 'expectedPrognosis',
);



has natural_progression => (
    is        => 'rw',
    predicate => '_has_natural_progression',
    json_ld   => 'naturalProgression',
);



has pathophysiology => (
    is        => 'rw',
    predicate => '_has_pathophysiology',
    json_ld   => 'pathophysiology',
);



has possible_complication => (
    is        => 'rw',
    predicate => '_has_possible_complication',
    json_ld   => 'possibleComplication',
);



has possible_treatment => (
    is        => 'rw',
    predicate => '_has_possible_treatment',
    json_ld   => 'possibleTreatment',
);



has primary_prevention => (
    is        => 'rw',
    predicate => '_has_primary_prevention',
    json_ld   => 'primaryPrevention',
);



has risk_factor => (
    is        => 'rw',
    predicate => '_has_risk_factor',
    json_ld   => 'riskFactor',
);



has secondary_prevention => (
    is        => 'rw',
    predicate => '_has_secondary_prevention',
    json_ld   => 'secondaryPrevention',
);



has sign_or_symptom => (
    is        => 'rw',
    predicate => '_has_sign_or_symptom',
    json_ld   => 'signOrSymptom',
);



has stage => (
    is        => 'rw',
    predicate => '_has_stage',
    json_ld   => 'stage',
);



has status => (
    is        => 'rw',
    predicate => '_has_status',
    json_ld   => 'status',
);



has typical_test => (
    is        => 'rw',
    predicate => '_has_typical_test',
    json_ld   => 'typicalTest',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalCondition - Any condition of the human body that affects the normal functioning of a person

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

Any condition of the human body that affects the normal functioning of a
person, whether physically or mentally. Includes diseases, injuries,
disabilities, disorders, syndromes, etc.

=head1 ATTRIBUTES

=head2 C<associated_anatomy>

C<associatedAnatomy>

The anatomy of the underlying organ system or structures associated with
this entity.

A associated_anatomy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalSystem']>

=item C<InstanceOf['SemanticWeb::Schema::SuperficialAnatomy']>

=back

=head2 C<_has_associated_anatomy>

A predicate for the L</associated_anatomy> attribute.

=head2 C<differential_diagnosis>

C<differentialDiagnosis>

One of a set of differential diagnoses for the condition. Specifically, a
closely-related or competing diagnosis typically considered later in the
cognitive process whereby this medical condition is distinguished from
others most likely responsible for a similar collection of signs and
symptoms to reach the most parsimonious diagnosis or diagnoses in a
patient.

A differential_diagnosis should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DDxElement']>

=back

=head2 C<_has_differential_diagnosis>

A predicate for the L</differential_diagnosis> attribute.

=head2 C<drug>

Specifying a drug or medicine used in a medication procedure

A drug should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Drug']>

=back

=head2 C<_has_drug>

A predicate for the L</drug> attribute.

=head2 C<epidemiology>

The characteristics of associated patients, such as age, gender, race etc.

A epidemiology should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_epidemiology>

A predicate for the L</epidemiology> attribute.

=head2 C<expected_prognosis>

C<expectedPrognosis>

The likely outcome in either the short term or long term of the medical
condition.

A expected_prognosis should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_expected_prognosis>

A predicate for the L</expected_prognosis> attribute.

=head2 C<natural_progression>

C<naturalProgression>

The expected progression of the condition if it is not treated and allowed
to progress naturally.

A natural_progression should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_natural_progression>

A predicate for the L</natural_progression> attribute.

=head2 C<pathophysiology>

Changes in the normal mechanical, physical, and biochemical functions that
are associated with this activity or condition.

A pathophysiology should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_pathophysiology>

A predicate for the L</pathophysiology> attribute.

=head2 C<possible_complication>

C<possibleComplication>

A possible unexpected and unfavorable evolution of a medical condition.
Complications may include worsening of the signs or symptoms of the
disease, extension of the condition to other organ systems, etc.

A possible_complication should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_possible_complication>

A predicate for the L</possible_complication> attribute.

=head2 C<possible_treatment>

C<possibleTreatment>

A possible treatment to address this condition, sign or symptom.

A possible_treatment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head2 C<_has_possible_treatment>

A predicate for the L</possible_treatment> attribute.

=head2 C<primary_prevention>

C<primaryPrevention>

A preventative therapy used to prevent an initial occurrence of the medical
condition, such as vaccination.

A primary_prevention should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head2 C<_has_primary_prevention>

A predicate for the L</primary_prevention> attribute.

=head2 C<risk_factor>

C<riskFactor>

A modifiable or non-modifiable factor that increases the risk of a patient
contracting this condition, e.g. age, coexisting condition.

A risk_factor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalRiskFactor']>

=back

=head2 C<_has_risk_factor>

A predicate for the L</risk_factor> attribute.

=head2 C<secondary_prevention>

C<secondaryPrevention>

A preventative therapy used to prevent reoccurrence of the medical
condition after an initial episode of the condition.

A secondary_prevention should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head2 C<_has_secondary_prevention>

A predicate for the L</secondary_prevention> attribute.

=head2 C<sign_or_symptom>

C<signOrSymptom>

A sign or symptom of this condition. Signs are objective or physically
observable manifestations of the medical condition while symptoms are the
subjective experience of the medical condition.

A sign_or_symptom should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalSignOrSymptom']>

=back

=head2 C<_has_sign_or_symptom>

A predicate for the L</sign_or_symptom> attribute.

=head2 C<stage>

The stage of the condition, if applicable.

A stage should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalConditionStage']>

=back

=head2 C<_has_stage>

A predicate for the L</stage> attribute.

=head2 C<status>

The status of the study (enumerated).

A status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EventStatusType']>

=item C<InstanceOf['SemanticWeb::Schema::MedicalStudyStatus']>

=item C<Str>

=back

=head2 C<_has_status>

A predicate for the L</status> attribute.

=head2 C<typical_test>

C<typicalTest>

A medical test typically performed given this condition.

A typical_test should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTest']>

=back

=head2 C<_has_typical_test>

A predicate for the L</typical_test> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEntity>

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
