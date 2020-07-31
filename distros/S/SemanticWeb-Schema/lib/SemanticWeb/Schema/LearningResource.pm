use utf8;

package SemanticWeb::Schema::LearningResource;

# ABSTRACT: The LearningResource type can be used to indicate CreativeWork s (whether physical or digital) that have a particular and explicit orientation towards learning

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'LearningResource';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v9.0.0';


has assesses => (
    is        => 'rw',
    predicate => '_has_assesses',
    json_ld   => 'assesses',
);



has educational_alignment => (
    is        => 'rw',
    predicate => '_has_educational_alignment',
    json_ld   => 'educationalAlignment',
);



has educational_level => (
    is        => 'rw',
    predicate => '_has_educational_level',
    json_ld   => 'educationalLevel',
);



has educational_use => (
    is        => 'rw',
    predicate => '_has_educational_use',
    json_ld   => 'educationalUse',
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

SemanticWeb::Schema::LearningResource - The LearningResource type can be used to indicate CreativeWork s (whether physical or digital) that have a particular and explicit orientation towards learning

=head1 VERSION

version v9.0.0

=head1 DESCRIPTION

=for html <p>The LearningResource type can be used to indicate <a class="localLink"
href="http://schema.org/CreativeWork">CreativeWork</a>s (whether physical
or digital) that have a particular and explicit orientation towards
learning, education, skill acquisition, and other educational
purposes.<br/><br/> <a class="localLink"
href="http://schema.org/LearningResource">LearningResource</a> is expected
to be used as an addition to a primary type such as <a class="localLink"
href="http://schema.org/Book">Book</a>, <a class="localLink"
href="http://schema.org/Video">Video</a>, <a class="localLink"
href="http://schema.org/Product">Product</a> etc.<br/><br/> <a
class="localLink"
href="http://schema.org/EducationEvent">EducationEvent</a> serves a similar
purpose for event-like things (e.g. a <a class="localLink"
href="http://schema.org/Trip">Trip</a>). A <a class="localLink"
href="http://schema.org/LearningResource">LearningResource</a> may be
created as a result of an <a class="localLink"
href="http://schema.org/EducationEvent">EducationEvent</a>, for example by
recording one.<p>

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

=head2 C<educational_alignment>

C<educationalAlignment>

=for html <p>An alignment to an established educational framework.<br/><br/> This
property should not be used where the nature of the alignment can be
described using a simple property, for example to express that a resource
<a class="localLink" href="http://schema.org/teaches">teaches</a> or <a
class="localLink" href="http://schema.org/assesses">assesses</a> a
competency.<p>

A educational_alignment should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AlignmentObject']>

=back

=head2 C<_has_educational_alignment>

A predicate for the L</educational_alignment> attribute.

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

=head2 C<educational_use>

C<educationalUse>

The purpose of a work in the context of education; for example,
'assignment', 'group work'.

A educational_use should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_educational_use>

A predicate for the L</educational_use> attribute.

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

L<SemanticWeb::Schema::CreativeWork>

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
