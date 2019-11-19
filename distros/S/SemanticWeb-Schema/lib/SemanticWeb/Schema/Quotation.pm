use utf8;

package SemanticWeb::Schema::Quotation;

# ABSTRACT: A quotation

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Quotation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v5.0.1';


has spoken_by_character => (
    is        => 'rw',
    predicate => '_has_spoken_by_character',
    json_ld   => 'spokenByCharacter',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Quotation - A quotation

=head1 VERSION

version v5.0.1

=head1 DESCRIPTION

=for html <p>A quotation. Often but not necessarily from some written work,
attributable to a real world author and - if associated with a fictional
character - to any fictional Person. Use <a class="localLink"
href="http://schema.org/isBasedOn">isBasedOn</a> to link to source/origin.
The <a class="localLink" href="http://schema.org/recordedIn">recordedIn</a>
property can be used to reference a Quotation from an <a class="localLink"
href="http://schema.org/Event">Event</a>.<p>

=head1 ATTRIBUTES

=head2 C<spoken_by_character>

C<spokenByCharacter>

The (e.g. fictional) character, Person or Organization to whom the
quotation is attributed within the containing CreativeWork.

A spoken_by_character should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<_has_spoken_by_character>

A predicate for the L</spoken_by_character> attribute.

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

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
