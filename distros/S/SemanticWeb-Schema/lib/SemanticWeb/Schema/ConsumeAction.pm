use utf8;

package SemanticWeb::Schema::ConsumeAction;

# ABSTRACT: The act of ingesting information/resources/food.

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'ConsumeAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';


has action_accessibility_requirement => (
    is        => 'rw',
    predicate => '_has_action_accessibility_requirement',
    json_ld   => 'actionAccessibilityRequirement',
);



has expects_acceptance_of => (
    is        => 'rw',
    predicate => '_has_expects_acceptance_of',
    json_ld   => 'expectsAcceptanceOf',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ConsumeAction - The act of ingesting information/resources/food.

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

The act of ingesting information/resources/food.

=head1 ATTRIBUTES

=head2 C<action_accessibility_requirement>

C<actionAccessibilityRequirement>

A set of requirements that a must be fulfilled in order to perform an
Action. If more than one value is specied, fulfilling one set of
requirements will allow the Action to be performed.

A action_accessibility_requirement should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::ActionAccessSpecification']>

=back

=head2 C<_has_action_accessibility_requirement>

A predicate for the L</action_accessibility_requirement> attribute.

=head2 C<expects_acceptance_of>

C<expectsAcceptanceOf>

An Offer which must be accepted before the user can perform the Action. For
example, the user may need to buy a movie before being able to watch it.

A expects_acceptance_of should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Offer']>

=back

=head2 C<_has_expects_acceptance_of>

A predicate for the L</expects_acceptance_of> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Action>

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
