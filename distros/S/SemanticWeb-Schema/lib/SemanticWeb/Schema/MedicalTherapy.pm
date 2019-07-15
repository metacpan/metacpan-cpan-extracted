use utf8;

package SemanticWeb::Schema::MedicalTherapy;

# ABSTRACT: Any medical intervention designed to prevent

use Moo;

extends qw/ SemanticWeb::Schema::TherapeuticProcedure /;


use MooX::JSON_LD 'MedicalTherapy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has contraindication => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'contraindication',
);



has duplicate_therapy => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'duplicateTherapy',
);



has serious_adverse_outcome => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'seriousAdverseOutcome',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalTherapy - Any medical intervention designed to prevent

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Any medical intervention designed to prevent, treat, and cure human
diseases and medical conditions, including both curative and palliative
therapies. Medical therapies are typically processes of care relying upon
pharmacotherapy, behavioral therapy, supportive therapy (with fluid or
nutrition for example), or detoxification (e.g. hemodialysis) aimed at
improving or preventing a health condition.

=head1 ATTRIBUTES

=head2 C<contraindication>

A contraindication for this therapy.

A contraindication should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalContraindication']>

=item C<Str>

=back

=head2 C<duplicate_therapy>

C<duplicateTherapy>

A therapy that duplicates or overlaps this one.

A duplicate_therapy should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head2 C<serious_adverse_outcome>

C<seriousAdverseOutcome>

A possible serious complication and/or serious side effect of this therapy.
Serious adverse outcomes include those that are life-threatening; result in
death, disability, or permanent damage; require hospitalization or prolong
existing hospitalization; cause congenital anomalies or birth defects; or
jeopardize the patient and may require medical or surgical intervention to
prevent one of the outcomes in this definition.

A serious_adverse_outcome should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::TherapeuticProcedure>

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
