use utf8;

package SemanticWeb::Schema::MediaReview;

# ABSTRACT: (editorial work in progress

use Moo;

extends qw/ SemanticWeb::Schema::Review /;


use MooX::JSON_LD 'MediaReview';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v7.0.3';


has media_authenticity_category => (
    is        => 'rw',
    predicate => '_has_media_authenticity_category',
    json_ld   => 'mediaAuthenticityCategory',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::MediaReview - (editorial work in progress

=head1 VERSION

version v7.0.3

=head1 DESCRIPTION

=for html <p>(editorial work in progress, this definition is incomplete and
unreviewed) A <a class="localLink"
href="http://schema.org/MediaReview">MediaReview</a> is a more specialized
form of Review dedicated to the evaluation of media content online,
typically in the context of fact-checking and misinformation. For more
general reviews of media in the broader sense, use <a class="localLink"
href="http://schema.org/UserReview">UserReview</a>, <a class="localLink"
href="http://schema.org/CriticReview">CriticReview</a> or other <a
class="localLink" href="http://schema.org/Review">Review</a> types.<p>

=head1 ATTRIBUTES

=head2 C<media_authenticity_category>

C<mediaAuthenticityCategory>

Indicates a MediaManipulationRatingEnumeration classification of a media
object (in the context of how it was published or shared).

A media_authenticity_category should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::MediaManipulationRatingEnumeration']>

=back

=head2 C<_has_media_authenticity_category>

A predicate for the L</media_authenticity_category> attribute.

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
