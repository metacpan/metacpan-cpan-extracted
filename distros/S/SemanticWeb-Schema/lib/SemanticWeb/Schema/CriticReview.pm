use utf8;

package SemanticWeb::Schema::CriticReview;

# ABSTRACT: A CriticReview is a more specialized form of Review written or published by a source that is recognized for its reviewing activities

use Moo;

extends qw/ SemanticWeb::Schema::Review /;


use MooX::JSON_LD 'CriticReview';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CriticReview - A CriticReview is a more specialized form of Review written or published by a source that is recognized for its reviewing activities

=head1 VERSION

version v7.0.4

=head1 DESCRIPTION

=for html <p>A <a class="localLink"
href="http://schema.org/CriticReview">CriticReview</a> is a more
specialized form of Review written or published by a source that is
recognized for its reviewing activities. These can include online columns,
travel and food guides, TV and radio shows, blogs and other independent Web
sites. <a class="localLink"
href="http://schema.org/CriticReview">CriticReview</a>s are typically more
in-depth and professionally written. For simpler, casually written
user/visitor/viewer/customer reviews, it is more appropriate to use the <a
class="localLink" href="http://schema.org/UserReview">UserReview</a> type.
Review aggregator sites such as Metacritic already separate out the site's
user reviews from selected critic reviews that originate from third-party
sources.<p>

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
