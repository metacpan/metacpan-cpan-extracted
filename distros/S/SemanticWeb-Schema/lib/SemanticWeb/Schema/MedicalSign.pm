use utf8;

package SemanticWeb::Schema::MedicalSign;

# ABSTRACT: Any physical manifestation of a person's medical condition discoverable by objective diagnostic tests or physical examination.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalSignOrSymptom /;


use MooX::JSON_LD 'MedicalSign';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has identifying_exam => (
    is        => 'rw',
    predicate => '_has_identifying_exam',
    json_ld   => 'identifyingExam',
);



has identifying_test => (
    is        => 'rw',
    predicate => '_has_identifying_test',
    json_ld   => 'identifyingTest',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalSign - Any physical manifestation of a person's medical condition discoverable by objective diagnostic tests or physical examination.

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

Any physical manifestation of a person's medical condition discoverable by
objective diagnostic tests or physical examination.

=head1 ATTRIBUTES

=head2 C<identifying_exam>

C<identifyingExam>

A physical examination that can identify this sign.

A identifying_exam should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PhysicalExam']>

=back

=head2 C<_has_identifying_exam>

A predicate for the L</identifying_exam> attribute.

=head2 C<identifying_test>

C<identifyingTest>

A diagnostic test that can identify this sign.

A identifying_test should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTest']>

=back

=head2 C<_has_identifying_test>

A predicate for the L</identifying_test> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalSignOrSymptom>

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
