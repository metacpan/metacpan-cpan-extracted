use utf8;

package SemanticWeb::Schema::Hospital;

# ABSTRACT: A hospital.

use Moo;

extends qw/ SemanticWeb::Schema::EmergencyService SemanticWeb::Schema::MedicalOrganization SemanticWeb::Schema::CivicStructure /;


use MooX::JSON_LD 'Hospital';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has available_service => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'availableService',
);



has medical_specialty => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'medicalSpecialty',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Hospital - A hospital.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A hospital.

=head1 ATTRIBUTES

=head2 C<available_service>

C<availableService>

A medical service available from this provider.

A available_service should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=item C<InstanceOf['SemanticWeb::Schema::MedicalTest']>

=item C<InstanceOf['SemanticWeb::Schema::MedicalProcedure']>

=back

=head2 C<medical_specialty>

C<medicalSpecialty>

A medical specialty of the provider.

A medical_specialty should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalSpecialty']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CivicStructure>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
