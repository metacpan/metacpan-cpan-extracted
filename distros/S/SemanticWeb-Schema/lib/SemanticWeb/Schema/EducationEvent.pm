use utf8;

package SemanticWeb::Schema::EducationEvent;

# ABSTRACT: Event type: Education event.

use Moo;

extends qw/ SemanticWeb::Schema::Event /;


use MooX::JSON_LD 'EducationEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v8.0.0';


has assesses => (
    is        => 'rw',
    predicate => '_has_assesses',
    json_ld   => 'assesses',
);



has educational_level => (
    is        => 'rw',
    predicate => '_has_educational_level',
    json_ld   => 'educationalLevel',
);



has teaches => (
    is        => 'rw',
    predicate => '_has_teaches',
    json_ld   => 'teaches',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EducationEvent - Event type: Education event.

=head1 VERSION

version v8.0.0

=head1 DESCRIPTION

Event type: Education event.

=head1 ATTRIBUTES

=head2 C<assesses>

The item being described is intended to assess the competency or learning
outcome defined by the referenced term.

A assesses should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_assesses>

A predicate for the L</assesses> attribute.

=head2 C<educational_level>

C<educationalLevel>

The level in terms of progression through an educational or training
context. Examples of educational levels include 'beginner', 'intermediate'
or 'advanced', and formal sets of level indicators.

A educational_level should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_educational_level>

A predicate for the L</educational_level> attribute.

=head2 C<teaches>

The item being described is intended to help a person learn the competency
or learning outcome defined by the referenced term.

A teaches should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DefinedTerm']>

=item C<Str>

=back

=head2 C<_has_teaches>

A predicate for the L</teaches> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Event>

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
