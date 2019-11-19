use utf8;

package SemanticWeb::Schema::MedicalProcedure;

# ABSTRACT: A process of care used in either a diagnostic

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalProcedure';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has body_location => (
    is        => 'rw',
    predicate => '_has_body_location',
    json_ld   => 'bodyLocation',
);



has followup => (
    is        => 'rw',
    predicate => '_has_followup',
    json_ld   => 'followup',
);



has how_performed => (
    is        => 'rw',
    predicate => '_has_how_performed',
    json_ld   => 'howPerformed',
);



has indication => (
    is        => 'rw',
    predicate => '_has_indication',
    json_ld   => 'indication',
);



has outcome => (
    is        => 'rw',
    predicate => '_has_outcome',
    json_ld   => 'outcome',
);



has preparation => (
    is        => 'rw',
    predicate => '_has_preparation',
    json_ld   => 'preparation',
);



has procedure_type => (
    is        => 'rw',
    predicate => '_has_procedure_type',
    json_ld   => 'procedureType',
);



has status => (
    is        => 'rw',
    predicate => '_has_status',
    json_ld   => 'status',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalProcedure - A process of care used in either a diagnostic

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

A process of care used in either a diagnostic, therapeutic, preventive or
palliative capacity that relies on invasive (surgical), non-invasive, or
other techniques.

=head1 ATTRIBUTES

=head2 C<body_location>

C<bodyLocation>

Location in the body of the anatomical structure.

A body_location should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_body_location>

A predicate for the L</body_location> attribute.

=head2 C<followup>

Typical or recommended followup care after the procedure is performed.

A followup should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_followup>

A predicate for the L</followup> attribute.

=head2 C<how_performed>

C<howPerformed>

How the procedure is performed.

A how_performed should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_how_performed>

A predicate for the L</how_performed> attribute.

=head2 C<indication>

A factor that indicates use of this therapy for treatment and/or prevention
of a condition, symptom, etc. For therapies such as drugs, indications can
include both officially-approved indications as well as off-label uses.
These can be distinguished by using the ApprovedIndication subtype of
MedicalIndication.

A indication should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalIndication']>

=back

=head2 C<_has_indication>

A predicate for the L</indication> attribute.

=head2 C<outcome>

Expected or actual outcomes of the study.

A outcome should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

=item C<Str>

=back

=head2 C<_has_outcome>

A predicate for the L</outcome> attribute.

=head2 C<preparation>

Typical preparation that a patient must undergo before having the procedure
performed.

A preparation should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

=item C<Str>

=back

=head2 C<_has_preparation>

A predicate for the L</preparation> attribute.

=head2 C<procedure_type>

C<procedureType>

The type of procedure, for example Surgical, Noninvasive, or Percutaneous.

A procedure_type should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalProcedureType']>

=back

=head2 C<_has_procedure_type>

A predicate for the L</procedure_type> attribute.

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
