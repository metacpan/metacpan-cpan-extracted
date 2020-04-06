use utf8;

package SemanticWeb::Schema::UpdateAction;

# ABSTRACT: The act of managing by changing/editing the state of the object.

use Moo;

extends qw/ SemanticWeb::Schema::Action /;


use MooX::JSON_LD 'UpdateAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has collection => (
    is        => 'rw',
    predicate => '_has_collection',
    json_ld   => 'collection',
);



has target_collection => (
    is        => 'rw',
    predicate => '_has_target_collection',
    json_ld   => 'targetCollection',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::UpdateAction - The act of managing by changing/editing the state of the object.

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

The act of managing by changing/editing the state of the object.

=head1 ATTRIBUTES

=head2 C<collection>

A sub property of object. The collection target of the action.

A collection should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<_has_collection>

A predicate for the L</collection> attribute.

=head2 C<target_collection>

C<targetCollection>

A sub property of object. The collection target of the action.

A target_collection should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<_has_target_collection>

A predicate for the L</target_collection> attribute.

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
