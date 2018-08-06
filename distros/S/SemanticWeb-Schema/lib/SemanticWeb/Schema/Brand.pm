package SemanticWeb::Schema::Brand;

# ABSTRACT: A brand is a name used by an organization or business person for labeling a product

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Brand';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has aggregate_rating => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'aggregateRating',
);



has logo => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'logo',
);



has review => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'review',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Brand - A brand is a name used by an organization or business person for labeling a product

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A brand is a name used by an organization or business person for labeling a
product, product group, or similar.

=head1 ATTRIBUTES

=head2 C<aggregate_rating>

C<aggregateRating>

The overall rating, based on a collection of reviews or ratings, of the
item.

A aggregate_rating should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::AggregateRating']>

=back

=head2 C<logo>

An associated logo.

A logo should be one of the following types:

=over

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::ImageObject']>

=back

=head2 C<review>

A review of the item.

A review should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Review']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
