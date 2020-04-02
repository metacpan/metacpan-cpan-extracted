use utf8;

package SemanticWeb::Schema::Guide;

# ABSTRACT:  Guide is a page or article that recommend specific products or services

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Guide';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.2';


has review_aspect => (
    is        => 'rw',
    predicate => '_has_review_aspect',
    json_ld   => 'reviewAspect',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Guide - Guide is a page or article that recommend specific products or services

=head1 VERSION

version v7.0.2

=head1 DESCRIPTION

=for html <p><a class="localLink" href="http://schema.org/Guide">Guide</a> is a page
or article that recommend specific products or services, or aspects of a
thing for a user to consider. A <a class="localLink"
href="http://schema.org/Guide">Guide</a> may represent a Buying Guide and
detail aspects of products or services for a user to consider. A <a
class="localLink" href="http://schema.org/Guide">Guide</a> may represent a
Product Guide and recommend specific products or services. A <a
class="localLink" href="http://schema.org/Guide">Guide</a> may represent a
Ranked List and recommend specific products or services with ranking.<p>

=head1 ATTRIBUTES

=head2 C<review_aspect>

C<reviewAspect>

This Review or Rating is relevant to this part or facet of the
itemReviewed.

A review_aspect should be one of the following types:

=over

=item C<Str>

=back

=head2 C<_has_review_aspect>

A predicate for the L</review_aspect> attribute.

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
