use utf8;

package SemanticWeb::Schema::Claim;

# ABSTRACT: A <a class="localLink" href="http://schema

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Claim';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.9.0';


has appearance => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'appearance',
);



has first_appearance => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'firstAppearance',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Claim - A <a class="localLink" href="http://schema

=head1 VERSION

version v3.9.0

=head1 DESCRIPTION

=for html A <a class="localLink" href="http://schema.org/Claim">Claim</a> in
Schema.org represents a specific, factually-oriented claim that could be
the <a class="localLink"
href="http://schema.org/itemReviewed">itemReviewed</a> in a <a
class="localLink" href="http://schema.org/ClaimReview">ClaimReview</a>. The
content of a claim can be summarized with the <a class="localLink"
href="http://schema.org/text">text</a> property. Variations on well known
claims can have their common identity indicated via <a class="localLink"
href="http://schema.org/sameAs">sameAs</a> links, and summarized with a <a
class="localLink" href="http://schema.org/name">name</a>. Ideally, a <a
class="localLink" href="http://schema.org/Claim">Claim</a> description
includes enough contextual information to minimize the risk of ambiguity or
inclarity. In practice, many claims are better understood in the context in
which they appear or the interpretations provided by claim
reviews.<br/><br/> Beyond <a class="localLink"
href="http://schema.org/ClaimReview">ClaimReview</a>, the Claim type can be
associated with related creative works - for example a <a class="localLink"
href="http://schema.org/ScholaryArticle">ScholaryArticle</a> or <a
class="localLink" href="http://schema.org/Question">Question</a> might be
<a class="localLink" href="http://schema.org/about">about</a> some <a
class="localLink" href="http://schema.org/Claim">Claim</a>.<br/><br/> At
this time, Schema.org does not define any types of relationship between
claims. This is a natural area for future exploration.

=head1 ATTRIBUTES

=head2 C<appearance>

=for html Indicates an occurence of a <a class="localLink"
href="http://schema.org/Claim">Claim</a> in some <a class="localLink"
href="http://schema.org/CreativeWork">CreativeWork</a>.

A appearance should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

=head2 C<first_appearance>

C<firstAppearance>

=for html Indicates the first known occurence of a <a class="localLink"
href="http://schema.org/Claim">Claim</a> in some <a class="localLink"
href="http://schema.org/CreativeWork">CreativeWork</a>.

A first_appearance should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::CreativeWork']>

=back

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
