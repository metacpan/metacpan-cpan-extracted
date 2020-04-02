use utf8;

package SemanticWeb::Schema::Recommendation;

# ABSTRACT:  Recommendation is a type of Review that suggests or proposes something as the best option or best course of action

use Moo;

extends qw/ SemanticWeb::Schema::Review /;


use MooX::JSON_LD 'Recommendation';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


has category => (
    is        => 'rw',
    predicate => '_has_category',
    json_ld   => 'category',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Recommendation - Recommendation is a type of Review that suggests or proposes something as the best option or best course of action

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

=for html <p><a class="localLink"
href="http://schema.org/Recommendation">Recommendation</a> is a type of <a
class="localLink" href="http://schema.org/Review">Review</a> that suggests
or proposes something as the best option or best course of action.
Recommendations may be for products or services, or other concrete things,
as in the case of a ranked list or product guide. A <a class="localLink"
href="http://schema.org/Guide">Guide</a> may list multiple recommendations
for different categories. For example, in a <a class="localLink"
href="http://schema.org/Guide">Guide</a> about which TVs to buy, the author
may have several <a class="localLink"
href="http://schema.org/Recommendation">Recommendation</a>s.<p>

=head1 ATTRIBUTES

=head2 C<category>

A category for the item. Greater signs or slashes can be used to informally
indicate a category hierarchy.

A category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::PhysicalActivityCategory']>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=item C<Str>

=back

=head2 C<_has_category>

A predicate for the L</category> attribute.

=head1 SEE ALSO

L<SemanticWeb::Schema::Review>

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
