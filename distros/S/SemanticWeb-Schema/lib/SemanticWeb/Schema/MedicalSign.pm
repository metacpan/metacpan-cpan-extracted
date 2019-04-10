use utf8;

package SemanticWeb::Schema::MedicalSign;

# ABSTRACT: Any physical manifestation of a person's medical condition discoverable by objective diagnostic tests or physical examination.

use Moo;

extends qw/ SemanticWeb::Schema::MedicalSignOrSymptom /;


use MooX::JSON_LD 'MedicalSign';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has identifying_exam => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'identifyingExam',
);



has identifying_test => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'identifyingTest',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalSign - Any physical manifestation of a person's medical condition discoverable by objective diagnostic tests or physical examination.

=head1 VERSION

version v3.5.0

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

=head2 C<identifying_test>

C<identifyingTest>

A diagnostic test that can identify this sign.

A identifying_test should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTest']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalSignOrSymptom>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
