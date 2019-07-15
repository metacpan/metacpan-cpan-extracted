use utf8;

package SemanticWeb::Schema::MedicalGuideline;

# ABSTRACT: Any recommendation made by a standard society (e

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalGuideline';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has evidence_level => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'evidenceLevel',
);



has evidence_origin => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'evidenceOrigin',
);



has guideline_date => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'guidelineDate',
);



has guideline_subject => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'guidelineSubject',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalGuideline - Any recommendation made by a standard society (e

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

Any recommendation made by a standard society (e.g. ACC/AHA) or consensus
statement that denotes how to diagnose and treat a particular condition.
Note: this type should be used to tag the actual guideline recommendation;
if the guideline recommendation occurs in a larger scholarly article, use
MedicalScholarlyArticle to tag the overall article, not this type. Note
also: the organization making the recommendation should be captured in the
recognizingAuthority base property of MedicalEntity.

=head1 ATTRIBUTES

=head2 C<evidence_level>

C<evidenceLevel>

Strength of evidence of the data used to formulate the guideline
(enumerated).

A evidence_level should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEvidenceLevel']>

=back

=head2 C<evidence_origin>

C<evidenceOrigin>

Source of the data used to formulate the guidance, e.g. RCT, consensus
opinion, etc.

A evidence_origin should be one of the following types:

=over

=item C<Str>

=back

=head2 C<guideline_date>

C<guidelineDate>

Date on which this guideline's recommendation was made.

A guideline_date should be one of the following types:

=over

=item C<Str>

=back

=head2 C<guideline_subject>

C<guidelineSubject>

The medical conditions, treatments, etc. that are the subject of the
guideline.

A guideline_subject should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

=back

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
