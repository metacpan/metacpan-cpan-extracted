use utf8;

package SemanticWeb::Schema::MedicalEntity;

# ABSTRACT: The most generic type of entity related to health and the practice of medicine.

use Moo;

extends qw/ SemanticWeb::Schema::Thing /;


use MooX::JSON_LD 'MedicalEntity';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has code => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'code',
);



has guideline => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'guideline',
);



has legal_status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'legalStatus',
);



has medicine_system => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'medicineSystem',
);



has recognizing_authority => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'recognizingAuthority',
);



has relevant_specialty => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'relevantSpecialty',
);



has study => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'study',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalEntity - The most generic type of entity related to health and the practice of medicine.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

The most generic type of entity related to health and the practice of
medicine.

=head1 ATTRIBUTES

=head2 C<code>

A medical code for the entity, taken from a controlled vocabulary or
ontology such as ICD-9, DiseasesDB, MeSH, SNOMED-CT, RxNorm, etc.

A code should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCode']>

=back

=head2 C<guideline>

A medical guideline related to this entity.

A guideline should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalGuideline']>

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

=head2 C<medicine_system>

C<medicineSystem>

The system of medicine that includes this MedicalEntity, for example
'evidence-based', 'homeopathic', 'chiropractic', etc.

A medicine_system should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicineSystem']>

=back

=head2 C<recognizing_authority>

C<recognizingAuthority>

If applicable, the organization that officially recognizes this entity as
part of its endorsed system of medicine.

A recognizing_authority should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head2 C<relevant_specialty>

C<relevantSpecialty>

If applicable, a medical specialty in which this entity is relevant.

A relevant_specialty should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalSpecialty']>

=back

=head2 C<study>

A medical study or trial related to this entity.

A study should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalStudy']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Thing>

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
