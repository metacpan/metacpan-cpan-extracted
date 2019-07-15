use utf8;

package SemanticWeb::Schema::MedicalConditionStage;

# ABSTRACT: A stage of a medical condition

use Moo;

extends qw/ SemanticWeb::Schema::MedicalIntangible /;


use MooX::JSON_LD 'MedicalConditionStage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has stage_as_number => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'stageAsNumber',
);



has sub_stage_suffix => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'subStageSuffix',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MedicalConditionStage - A stage of a medical condition

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A stage of a medical condition, such as 'Stage IIIa'.

=head1 ATTRIBUTES

=head2 C<stage_as_number>

C<stageAsNumber>

The stage represented as a number, e.g. 3.

A stage_as_number should be one of the following types:

=over

=item C<Num>

=back

=head2 C<sub_stage_suffix>

C<subStageSuffix>

The substage, e.g. 'a' for Stage IIIa.

A sub_stage_suffix should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalIntangible>

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
