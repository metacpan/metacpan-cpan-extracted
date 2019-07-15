use utf8;

package SemanticWeb::Schema::MedicalObservationalStudy;

# ABSTRACT: An observational study is a type of medical study that attempts to infer the possible effect of a treatment through observation of a cohort of subjects over a period of time

use Moo;

extends qw/ SemanticWeb::Schema::MedicalStudy /;


use MooX::JSON_LD 'MedicalObservationalStudy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has study_design => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'studyDesign',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalObservationalStudy - An observational study is a type of medical study that attempts to infer the possible effect of a treatment through observation of a cohort of subjects over a period of time

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

An observational study is a type of medical study that attempts to infer
the possible effect of a treatment through observation of a cohort of
subjects over a period of time. In an observational study, the assignment
of subjects into treatment groups versus control groups is outside the
control of the investigator. This is in contrast with controlled studies,
such as the randomized controlled trials represented by MedicalTrial, where
each subject is randomly assigned to a treatment group or a control group
before the start of the treatment.

=head1 ATTRIBUTES

=head2 C<study_design>

C<studyDesign>

Specifics about the observational study design (enumerated).

A study_design should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalObservationalStudyDesign']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalStudy>

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
