use utf8;

package SemanticWeb::Schema::DietarySupplement;

# ABSTRACT: A product taken by mouth that contains a dietary ingredient intended to supplement the diet

use Moo;

extends qw/ SemanticWeb::Schema::Substance /;


use MooX::JSON_LD 'DietarySupplement';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has active_ingredient => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'activeIngredient',
);



has background => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'background',
);



has is_proprietary => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'isProprietary',
);



has legal_status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'legalStatus',
);



has manufacturer => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'manufacturer',
);



has maximum_intake => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'maximumIntake',
);



has mechanism_of_action => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'mechanismOfAction',
);



has non_proprietary_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'nonProprietaryName',
);



has proprietary_name => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'proprietaryName',
);



has recommended_intake => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recommendedIntake',
);



has safety_consideration => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'safetyConsideration',
);



has target_population => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'targetPopulation',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DietarySupplement - A product taken by mouth that contains a dietary ingredient intended to supplement the diet

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A product taken by mouth that contains a dietary ingredient intended to
supplement the diet. Dietary ingredients may include vitamins, minerals,
herbs or other botanicals, amino acids, and substances such as enzymes,
organ tissues, glandulars and metabolites.

=head1 ATTRIBUTES

=head2 C<active_ingredient>

C<activeIngredient>

An active ingredient, typically chemical compounds and/or biologic
substances.

A active_ingredient should be one of the following types:

=over

=item C<Str>

=back

=head2 C<background>

Descriptive information establishing a historical perspective on the
supplement. May include the rationale for the name, the population where
the supplement first came to prominence, etc.

A background should be one of the following types:

=over

=item C<Str>

=back

=head2 C<is_proprietary>

C<isProprietary>

True if this item's name is a proprietary/brand name (vs. generic name).

A is_proprietary should be one of the following types:

=over

=item C<Bool>

=back

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

=head2 C<manufacturer>

The manufacturer of the product.

A manufacturer should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<maximum_intake>

C<maximumIntake>

Recommended intake of this supplement for a given population as defined by
a specific recommending authority.

A maximum_intake should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MaximumDoseSchedule']>

=back

=head2 C<mechanism_of_action>

C<mechanismOfAction>

The specific biochemical interaction through which this drug or supplement
produces its pharmacological effect.

A mechanism_of_action should be one of the following types:

=over

=item C<Str>

=back

=head2 C<non_proprietary_name>

C<nonProprietaryName>

The generic name of this drug or supplement.

A non_proprietary_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<proprietary_name>

C<proprietaryName>

Proprietary name given to the diet plan, typically by its originator or
creator.

A proprietary_name should be one of the following types:

=over

=item C<Str>

=back

=head2 C<recommended_intake>

C<recommendedIntake>

Recommended intake of this supplement for a given population as defined by
a specific recommending authority.

A recommended_intake should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::RecommendedDoseSchedule']>

=back

=head2 C<safety_consideration>

C<safetyConsideration>

Any potential safety concern associated with the supplement. May include
interactions with other drugs and foods, pregnancy, breastfeeding, known
adverse reactions, and documented efficacy of the supplement.

A safety_consideration should be one of the following types:

=over

=item C<Str>

=back

=head2 C<target_population>

C<targetPopulation>

Characteristics of the population for which this is intended, or which
typically uses it, e.g. 'adults'.

A target_population should be one of the following types:

=over

=item C<Str>

=back

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
