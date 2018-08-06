package SemanticWeb::Schema::AggregateRating;

# ABSTRACT: The average rating based on multiple ratings or reviews.

use Moo;

extends qw/ SemanticWeb::Schema::Rating /;


use MooX::JSON_LD 'AggregateRating';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has item_reviewed => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'itemReviewed',
);



has rating_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'ratingCount',
);



has review_count => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'reviewCount',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::AggregateRating - The average rating based on multiple ratings or reviews.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

The average rating based on multiple ratings or reviews.

=head1 ATTRIBUTES

=head2 C<item_reviewed>

C<itemReviewed>

The item that is being reviewed/rated.

A item_reviewed should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head2 C<rating_count>

C<ratingCount>

The count of total number of ratings.

A rating_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head2 C<review_count>

C<reviewCount>

The count of total number of reviews.

A review_count should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Integer']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Rating>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
