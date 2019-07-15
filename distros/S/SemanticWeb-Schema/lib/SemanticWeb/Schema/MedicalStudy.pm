use utf8;

package SemanticWeb::Schema::MedicalStudy;

# ABSTRACT: A medical study is an umbrella type covering all kinds of research studies relating to human medicine or health

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'MedicalStudy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has health_condition => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'healthCondition',
);



has outcome => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'outcome',
);



has population => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'population',
);



has sponsor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sponsor',
);



has status => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'status',
);



has study_location => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'studyLocation',
);



has study_subject => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'studySubject',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalStudy - A medical study is an umbrella type covering all kinds of research studies relating to human medicine or health

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A medical study is an umbrella type covering all kinds of research studies
relating to human medicine or health, including observational studies and
interventional trials and registries, randomized, controlled or not. When
the specific type of study is known, use one of the extensions of this
type, such as MedicalTrial or MedicalObservationalStudy. Also, note that
this type should be used to mark up data that describes the study itself;
to tag an article that publishes the results of a study, use
MedicalScholarlyArticle. Note: use the code property of MedicalEntity to
store study IDs, e.g. clinicaltrials.gov ID.

=head1 ATTRIBUTES

=head2 C<health_condition>

C<healthCondition>

Specifying the health condition(s) of a patient, medical study, or other
target audience.

A health_condition should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalCondition']>

=back

=head2 C<outcome>

Expected or actual outcomes of the study.

A outcome should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalEntity']>

=item C<Str>

=back

=head2 C<population>

Any characteristics of the population used in the study, e.g. 'males under
65'.

A population should be one of the following types:

=over

=item C<Str>

=back

=head2 C<sponsor>

A person or organization that supports a thing through a pledge, promise,
or financial contribution. e.g. a sponsor of a Medical Study or a corporate
sponsor of an event.

A sponsor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<status>

The status of the study (enumerated).

A status should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::EventStatusType']>

=item C<InstanceOf['SemanticWeb::Schema::MedicalStudyStatus']>

=item C<Str>

=back

=head2 C<study_location>

C<studyLocation>

The location in which the study is taking/took place.

A study_location should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AdministrativeArea']>

=back

=head2 C<study_subject>

C<studySubject>

A subject of the study, i.e. one of the medical conditions, therapies,
devices, drugs, etc. investigated by the study.

A study_subject should be one of the following types:

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
