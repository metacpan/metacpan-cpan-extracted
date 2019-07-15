use utf8;

package SemanticWeb::Schema::MedicalTrial;

# ABSTRACT: A medical trial is a type of medical study that uses scientific process used to compare the safety and efficacy of medical therapies or medical procedures

use Moo;

extends qw/ SemanticWeb::Schema::MedicalStudy /;


use MooX::JSON_LD 'MedicalTrial';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has phase => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'phase',
);



has trial_design => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'trialDesign',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalTrial - A medical trial is a type of medical study that uses scientific process used to compare the safety and efficacy of medical therapies or medical procedures

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A medical trial is a type of medical study that uses scientific process
used to compare the safety and efficacy of medical therapies or medical
procedures. In general, medical trials are controlled and subjects are
allocated at random to the different treatment and/or control groups.

=head1 ATTRIBUTES

=head2 C<phase>

The phase of the clinical trial.

A phase should be one of the following types:

=over

=item C<Str>

=back

=head2 C<trial_design>

C<trialDesign>

Specifics about the trial design (enumerated).

A trial_design should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MedicalTrialDesign']>

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
