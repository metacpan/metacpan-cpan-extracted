package SemanticWeb::Schema::DataFeed;

# ABSTRACT: A single feed providing structured information about one or more entities or topics.

use Moo;

extends qw/ SemanticWeb::Schema::Dataset /;


use MooX::JSON_LD 'DataFeed';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has data_feed_element => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'dataFeedElement',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DataFeed - A single feed providing structured information about one or more entities or topics.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A single feed providing structured information about one or more entities
or topics.

=head1 ATTRIBUTES

=head2 C<data_feed_element>

C<dataFeedElement>

An item within in a data feed. Data feeds may have many elements.

A data_feed_element should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::DataFeedItem']>

=item C<Str>

=item C<InstanceOf['SemanticWeb::Schema::Thing']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Dataset>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
