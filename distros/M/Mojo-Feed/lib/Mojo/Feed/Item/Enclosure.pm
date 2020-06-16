package Mojo::Feed::Item::Enclosure;
use Mojo::Base -base;

use overload
  bool     => sub {1},
  '""'     => sub { shift->to_string },
  fallback => 1;


has 'dom';

has length => sub { shift->dom->attr('length'); };
has type   => sub { shift->dom->attr('type'); };
has url => sub { my $attr = shift->dom->attr; $attr->{url} || $attr->{href} };

sub to_hash {
  return {map { $_ => $_[0]->$_ } (qw(length type url))};
}

sub to_string {
  shift->dom->to_string;
}

1;

__END__

=encoding utf-8

=head1 NAME

Mojo::Feed::Item::Enclosure - represents a file enclosure in an item from an RSS/Atom feed.

=head1 SYNOPSIS

    use Mojo::Feed;

    my $feed = Mojo::Feed->new("atom.xml");

    my $item = $feed->items->first;

    print $item->title, $item->author, $item->published, "\n";

=head1 DESCRIPTION

L<Mojo::Feed::Item::Enclosure> is an Object wrapper for an enclosure from an RSS or Atom feed item.

=head1 ATTRIBUTES

L<Mojo::Feed::Item::Enclosure> implements the following attributes.

=head2  type

Mime type of the enclosure file

=head2  length

Length of the enclosure payload

=head2  url

URL for downloading the enclosure content

=head1 METHODS

L<Mojo::Feed::Item::Enclosure> inherits all methods from L<Mojo::Base> and adds the following ones:

=head2 to_hash

  my $hash = $enclosure->to_hash;
  print $hash->{url};

Return a hash reference representing the enclosure.

=head2 to_string

Return a XML serialized text of the enclosure's Mojo::DOM node. Note that this can be different from the original XML text in the feed.

=head1 CREDITS

Dotan Dimet

Mario Domgoergen

Some tests adapted from L<Feed::Find> and L<XML:Feed>, Feed auto-discovery adapted from L<Feed::Find>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Dotan Dimet E<lt>dotan@corky.netE<gt>.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

Test data (web pages, feeds and excerpts) included in this package is intended
for testing purposes only, and is not meant in any way to infringe on the
rights of the respective authors.

=head1 AUTHOR

Dotan Dimet E<lt>dotan@corky.netE<gt>

=cut
