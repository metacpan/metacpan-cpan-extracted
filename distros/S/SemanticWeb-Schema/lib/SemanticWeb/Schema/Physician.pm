use utf8;

package SemanticWeb::Schema::Physician;

# ABSTRACT: A doctor's office.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalBusiness SemanticWeb::Schema::MedicalOrganization /;


use MooX::JSON_LD 'Physician';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has available_service => (
    is        => 'rw',
    predicate => '_has_available_service',
    json_ld   => 'availableService',
);



has hospital_affiliation => (
    is        => 'rw',
    predicate => '_has_hospital_affiliation',
    json_ld   => 'hospitalAffiliation',
);



has medical_specialty => (
    is        => 'rw',
    predicate => '_has_medical_specialty',
    json_ld   => 'medicalSpecialty',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Physician - A doctor's office.

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

A doctor's office.

=head1 ATTRIBUTES

=head2 C<available_service>

C<availableService>

A medical service available from this provider.

A available_service should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalProcedure']>

=item C<InstanceOf['SemanticWeb::Schema::MedicalTest']>

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head2 C<_has_available_service>

A predicate for the L</available_service> attribute.

=head2 C<hospital_affiliation>

C<hospitalAffiliation>

A hospital with which the physician or office is affiliated.

A hospital_affiliation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Hospital']>

=back

=head2 C<_has_hospital_affiliation>

A predicate for the L</hospital_affiliation> attribute.

=head2 C<medical_specialty>

C<medicalSpecialty>

A medical specialty of the provider.

A medical_specialty should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalSpecialty']>

=back

=head2 C<_has_medical_specialty>

A predicate for the L</medical_specialty> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalOrganization>

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
