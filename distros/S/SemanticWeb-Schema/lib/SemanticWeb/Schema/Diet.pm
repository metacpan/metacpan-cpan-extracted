use utf8;

package SemanticWeb::Schema::Diet;

# ABSTRACT: A strategy of regulating the intake of food to achieve or maintain a specific health-related goal.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork SemanticWeb::Schema::LifestyleModification /;


use MooX::JSON_LD 'Diet';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v6.0.1';


has diet_features => (
    is        => 'rw',
    predicate => '_has_diet_features',
    json_ld   => 'dietFeatures',
);



has endorsers => (
    is        => 'rw',
    predicate => '_has_endorsers',
    json_ld   => 'endorsers',
);



has expert_considerations => (
    is        => 'rw',
    predicate => '_has_expert_considerations',
    json_ld   => 'expertConsiderations',
);



has overview => (
    is        => 'rw',
    predicate => '_has_overview',
    json_ld   => 'overview',
);



has physiological_benefits => (
    is        => 'rw',
    predicate => '_has_physiological_benefits',
    json_ld   => 'physiologicalBenefits',
);



has risks => (
    is        => 'rw',
    predicate => '_has_risks',
    json_ld   => 'risks',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Diet - A strategy of regulating the intake of food to achieve or maintain a specific health-related goal.

=head1 VERSION

version v6.0.1

=head1 DESCRIPTION

A strategy of regulating the intake of food to achieve or maintain a
specific health-related goal.

=head1 ATTRIBUTES

=head2 C<diet_features>

C<dietFeatures>

Nutritional information specific to the dietary plan. May include dietary
recommendations on what foods to avoid, what foods to consume, and specific
alterations/deviations from the USDA or other regulatory body's approved
dietary guidelines.

A diet_features should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_diet_features>

A predicate for the L</diet_features> attribute.

=head2 C<endorsers>

People or organizations that endorse the plan.

A endorsers should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_endorsers>

A predicate for the L</endorsers> attribute.

=head2 C<expert_considerations>

C<expertConsiderations>

Medical expert advice related to the plan.

A expert_considerations should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_expert_considerations>

A predicate for the L</expert_considerations> attribute.

=head2 C<overview>

Descriptive information establishing the overarching theory/philosophy of
the plan. May include the rationale for the name, the population where the
plan first came to prominence, etc.

A overview should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_overview>

A predicate for the L</overview> attribute.

=head2 C<physiological_benefits>

C<physiologicalBenefits>

Specific physiologic benefits associated to the plan.

A physiological_benefits should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_physiological_benefits>

A predicate for the L</physiological_benefits> attribute.

=head2 C<risks>

Specific physiologic risks associated to the diet plan.

A risks should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_risks>

A predicate for the L</risks> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::LifestyleModification>

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
