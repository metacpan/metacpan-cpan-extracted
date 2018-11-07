use utf8;

package SemanticWeb::Schema::Review;

# ABSTRACT: A review of an item - for example

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'Review';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';


has item_reviewed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itemReviewed',
);



has review_body => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'reviewBody',
);



has review_rating => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'reviewRating',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Review - A review of an item - for example

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A review of an item - for example, of a restaurant, movie, or store.

=head1 ATTRIBUTES

=head2 C<item_reviewed>

C<itemReviewed>

The item that is being reviewed/rated.

A item_reviewed should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<review_body>

C<reviewBody>

The actual body of the review.

A review_body should be one of the following types:

=over

=item C<Str>

=back

=head2 C<review_rating>

C<reviewRating>

=for html The rating given in this review. Note that reviews can themselves be rated.
The <code>reviewRating</code> applies to rating given by the review. The <a
class="localLink"
href="http://schema.org/aggregateRating">aggregateRating</a> property
applies to the review itself, as a creative work.

A review_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Rating']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
