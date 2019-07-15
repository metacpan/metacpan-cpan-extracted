use utf8;

package SemanticWeb::Schema::Nerve;

# ABSTRACT: A common pathway for the electrochemical nerve impulses that are transmitted along each of the axons.

use Moo;

extends qw/ SemanticWeb::Schema::AnatomicalStructure /;


use MooX::JSON_LD 'Nerve';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has branch => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'branch',
);



has nerve_motor => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'nerveMotor',
);



has sensory_unit => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sensoryUnit',
);



has sourced_from => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'sourcedFrom',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Nerve - A common pathway for the electrochemical nerve impulses that are transmitted along each of the axons.

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A common pathway for the electrochemical nerve impulses that are
transmitted along each of the axons.

=head1 ATTRIBUTES

=head2 C<branch>

=for html The branches that delineate from the nerve bundle. Not to be confused with
<a class="localLink" href="http://schema.org/branchOf">branchOf</a>.

A branch should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=back

=head2 C<nerve_motor>

C<nerveMotor>

The neurological pathway extension that involves muscle control.

A nerve_motor should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Muscle']>

=back

=head2 C<sensory_unit>

C<sensoryUnit>

The neurological pathway extension that inputs and sends information to the
brain or spinal cord.

A sensory_unit should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=item C<InstanceOf['SemanticWeb::Schema::SuperficialAnatomy']>

=back

=head2 C<sourced_from>

C<sourcedFrom>

The neurological pathway that originates the neurons.

A sourced_from should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::BrainStructure']>

=back

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
