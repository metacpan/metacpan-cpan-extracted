use utf8;

package SemanticWeb::Schema::Nerve;

# ABSTRACT: A common pathway for the electrochemical nerve impulses that are transmitted along each of the axons.

use Moo;

extends qw/ SemanticWeb::Schema::AnatomicalStructure /;


use MooX::JSON_LD 'Nerve';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has branch => (
    is        => 'rw',
    predicate => '_has_branch',
    json_ld   => 'branch',
);



has nerve_motor => (
    is        => 'rw',
    predicate => '_has_nerve_motor',
    json_ld   => 'nerveMotor',
);



has sensory_unit => (
    is        => 'rw',
    predicate => '_has_sensory_unit',
    json_ld   => 'sensoryUnit',
);



has sourced_from => (
    is        => 'rw',
    predicate => '_has_sourced_from',
    json_ld   => 'sourcedFrom',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Nerve - A common pathway for the electrochemical nerve impulses that are transmitted along each of the axons.

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

A common pathway for the electrochemical nerve impulses that are
transmitted along each of the axons.

=head1 ATTRIBUTES

=head2 C<branch>

=for html <p>The branches that delineate from the nerve bundle. Not to be confused
with <a class="localLink"
href="http://schema.org/branchOf">branchOf</a>.<p>

A branch should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=back

=head2 C<_has_branch>

A predicate for the L</branch> attribute.

=head2 C<nerve_motor>

C<nerveMotor>

The neurological pathway extension that involves muscle control.

A nerve_motor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Muscle']>

=back

=head2 C<_has_nerve_motor>

A predicate for the L</nerve_motor> attribute.

=head2 C<sensory_unit>

C<sensoryUnit>

The neurological pathway extension that inputs and sends information to the
brain or spinal cord.

A sensory_unit should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=item C<InstanceOf['SemanticWeb::Schema::SuperficialAnatomy']>

=back

=head2 C<_has_sensory_unit>

A predicate for the L</sensory_unit> attribute.

=head2 C<sourced_from>

C<sourcedFrom>

The neurological pathway that originates the neurons.

A sourced_from should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BrainStructure']>

=back

=head2 C<_has_sourced_from>

A predicate for the L</sourced_from> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::AnatomicalStructure>

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
