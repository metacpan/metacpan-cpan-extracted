use utf8;

package SemanticWeb::Schema::MedicalSignOrSymptom;

# ABSTRACT: Any feature associated or not with a medical condition

use Moo;

extends qw/ SemanticWeb::Schema::MedicalCondition /;


use MooX::JSON_LD 'MedicalSignOrSymptom';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has cause => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'cause',
);



has possible_treatment => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'possibleTreatment',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalSignOrSymptom - Any feature associated or not with a medical condition

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Any feature associated or not with a medical condition. In medicine a
symptom is generally subjective while a sign is objective.

=head1 ATTRIBUTES

=head2 C<cause>

Specifying a cause of something in general. e.g in medicine , one of the
causative agent(s) that are most directly responsible for the
pathophysiologic process that eventually results in the occurrence.

A cause should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCause']>

=back

=head2 C<possible_treatment>

C<possibleTreatment>

A possible treatment to address this condition, sign or symptom.

A possible_treatment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTherapy']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalCondition>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
