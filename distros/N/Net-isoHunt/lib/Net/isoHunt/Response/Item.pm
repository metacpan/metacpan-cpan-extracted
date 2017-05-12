package Net::isoHunt::Response::Item;
BEGIN {
  $Net::isoHunt::Response::Item::VERSION = '0.102770';
}

# ABSTRACT: Provides accessors to item fields

use Moose;

has [
    qw{
        title
        link
        enclosure_url
        tracker
        tracker_url
        kws
        exempts
        category
        original_site
        original_link
        size
        hash
        pub_date
      }
    ] => (
    is  => 'ro',
    isa => 'Str',
);

has [
    qw{
        guid
        length
        files
        seeds
        leechers
        downloads
        votes
        comments
      }
    ] => (
    is  => 'ro',
    isa => 'Int',
);

__PACKAGE__->meta()->make_immutable();

no Moose;

1;



=pod

=head1 NAME

Net::isoHunt::Response::Item - Provides accessors to item fields

=head1 VERSION

version 0.102770

=head1 ATTRIBUTES

=head2 C<title>

=head2 C<link>

=head2 C<guid>

=head2 C<enclosure_url>

=head2 C<length>

=head2 C<tracker>

=head2 C<tracker_url>

=head2 C<kws>

=head2 C<exempts>

=head2 C<category>

=head2 C<original_site>

=head2 C<original_link>

=head2 C<size>

=head2 C<files>

=head2 C<seeds>

=head2 C<leechers>

=head2 C<downloads>

=head2 C<votes>

=head2 C<comments>

=head2 C<hash>

=head2 C<pub_date>

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

