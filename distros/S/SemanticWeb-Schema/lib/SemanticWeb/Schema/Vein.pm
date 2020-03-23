use utf8;

package SemanticWeb::Schema::Vein;

# ABSTRACT: A type of blood vessel that specifically carries blood to the heart.

use Moo;

extends qw/ SemanticWeb::Schema::Vessel /;


use MooX::JSON_LD 'Vein';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.0';


has drains_to => (
    is        => 'rw',
    predicate => '_has_drains_to',
    json_ld   => 'drainsTo',
);



has region_drained => (
    is        => 'rw',
    predicate => '_has_region_drained',
    json_ld   => 'regionDrained',
);



has tributary => (
    is        => 'rw',
    predicate => '_has_tributary',
    json_ld   => 'tributary',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Vein - A type of blood vessel that specifically carries blood to the heart.

=head1 VERSION

version v7.0.0

=head1 DESCRIPTION

A type of blood vessel that specifically carries blood to the heart.

=head1 ATTRIBUTES

=head2 C<drains_to>

C<drainsTo>

The vasculature that the vein drains into.

A drains_to should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Vessel']>

=back

=head2 C<_has_drains_to>

A predicate for the L</drains_to> attribute.

=head2 C<region_drained>

C<regionDrained>

The anatomical or organ system drained by this vessel; generally refers to
a specific part of an organ.

A region_drained should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalSystem']>

=back

=head2 C<_has_region_drained>

A predicate for the L</region_drained> attribute.

=head2 C<tributary>

The anatomical or organ system that the vein flows into; a larger structure
that the vein connects to.

A tributary should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AnatomicalStructure']>

=back

=head2 C<_has_tributary>

A predicate for the L</tributary> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Vessel>

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
