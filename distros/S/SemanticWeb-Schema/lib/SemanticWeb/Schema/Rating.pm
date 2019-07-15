use utf8;

package SemanticWeb::Schema::Rating;

# ABSTRACT: A rating is an evaluation on a numeric scale

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Rating';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.8.1';


has author => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'author',
);



has best_rating => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'bestRating',
);



has rating_value => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'ratingValue',
);



has review_aspect => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'reviewAspect',
);



has worst_rating => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'worstRating',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Rating - A rating is an evaluation on a numeric scale

=head1 VERSION

version v3.8.1

=head1 DESCRIPTION

A rating is an evaluation on a numeric scale, such as 1 to 5 stars.

=head1 ATTRIBUTES

=head2 C<author>

The author of this content or rating. Please note that author is special in
that HTML 5 provides a special mechanism for indicating authorship via the
rel tag. That is equivalent to this and may be used interchangeably.

A author should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=item C<InstanceOf['SemanticWeb::Schema::Person']>

=back

=head2 C<best_rating>

C<bestRating>

The highest value allowed in this rating system. If bestRating is omitted,
5 is assumed.

A best_rating should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<rating_value>

C<ratingValue>

=for html The rating for the content.<br/><br/> Usage guidelines:<br/><br/> <ul>
<li>Use values from 0123456789 (Unicode 'DIGIT ZERO' (U+0030) to 'DIGIT
NINE' (U+0039)) rather than superficially similiar Unicode symbols.</li>
<li>Use '.' (Unicode 'FULL STOP' (U+002E)) rather than ',' to indicate a
decimal point. Avoid using these symbols as a readability separator.</li>
</ul> 

A rating_value should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head2 C<review_aspect>

C<reviewAspect>

This Review or Rating is relevant to this part or facet of the
itemReviewed.

A review_aspect should be one of the following types:

=over

=item C<Str>

=back

=head2 C<worst_rating>

C<worstRating>

The lowest value allowed in this rating system. If worstRating is omitted,
1 is assumed.

A worst_rating should be one of the following types:

=over

=item C<Num>

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

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
