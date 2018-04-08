package Mojo::Feed::Item;
use Mojo::Base '-base';

use overload
  bool     => sub {1},
  '""'     => sub { shift->to_string },
  fallback => 1;

use Mojo::Feed::Item::Enclosure;
use HTTP::Date 'str2time';

has [qw(title link content id description guid published author)];

has tags => sub {
  shift->dom->find('category, dc\:subject')
    ->map(sub { $_[0]->text || $_[0]->attr('term') });
};

has 'dom';
has 'feed';

has summary => sub { shift->description };

my %selector = (
  content => ['content', 'content\:encoded', 'xhtml\:body', 'description'],
  description => ['description', 'summary'],
  published   => [
    'published', 'pubDate', 'dc\:date', 'created',
    'issued',    'updated', 'modified'
  ],
  author => ['author', 'dc\:creator'],
  id     => ['id',     'guid', 'link'],
  title => ['title'],
  link  => ['link'],
  guid  => ['guid'],
);

sub _at {
  my ($self, $selector) = @_;
  return $self->dom->find($selector)->first(sub {
    my $tag = $_->tag;
    $tag =~ s/:/\\:/;
    return $tag eq $selector;
  });
}

foreach my $k (keys %selector) {
  has $k => sub {
    my $self = shift;
    for my $selector (@{$selector{$k}}) {
      if (my $p = $self->_at($selector)) {
        if ($k eq 'author' && $p->at('name')) {
          return $p->at('name')->text;
        }
        my $text = $p->text || $p->content;
        if ($k eq 'published') {
          return str2time($text);
        }
        return $text;
      }
    }
    return;
  };
}

has enclosures => sub {
  my $self = shift;
  my @enclosures;
  $self->dom->find('enclosure')->each(sub {
    push @enclosures, $_;
  });
  $self->dom->find('link')->each(sub {
    my $l = shift;
    if ($l->attr('href') && $l->attr('rel') && $l->attr('rel') eq 'enclosure') {
      push @enclosures, $l;
    }
  });
  return Mojo::Collection->new(
    map { Mojo::Feed::Item::Enclosure->new(dom => $_) } @enclosures);
};

has link => sub {

  # let's handle links seperately, because ATOM loves these buggers:
  my $link;
  shift->dom->find('link')->each(sub {
    my $l = shift;
    if ($l->attr('href')
      && (!$l->attr('rel') || $l->attr('rel') eq 'alternate'))
    {
      $link = $l->attr('href');
    }
    else {
      if ($l->text =~ /\w+/) {
        $link = $l->text;    # simple link
      }
    }
  });
  return $link;
};

sub to_string {
  shift->dom->to_string;
}

sub to_hash {
  my $self = shift;
  my $hash = {map { $_ => '' . ($self->$_ || '') } keys %selector};
  if ($self->enclosures->size) {
    $hash->{'enclosures'} = $self->enclosures->map('to_hash')->to_array;
  }
  if ($self->tags->size) {
    $hash->{'tags'} = $self->tags->to_array;
  }
  return $hash;
}

1;

__END__

=encoding utf-8

=head1 NAME

Mojo::Feed::Item - represents an item from an RSS/Atom feed.

=head1 SYNOPSIS

    use Mojo::Feed;

    my $feed = Mojo::Feed->new("atom.xml");

    my $item = $feed->items->first;

    print $item->title, $item->author, $item->published, "\n";

=head1 DESCRIPTION

L<Mojo::Feed::Item> is an Object wrapper for a item from an RSS or Atom Feed.

=head1 ATTRIBUTES

L<Mojo::Feed::Item> implements the following attributes.

=head2  title

=head2  link

=head2  content

May be filled with C<content:encoded>, C<xhtml:body> or C<description> fields

=head2  id

Will be equal to C<link> or C<guid> if it is undefined and either of those fields exists

=head2  description

Optional - usually a shorter form of the content (may be filled with C<summary> if description is missing)

=head2  guid

Optional

=head2  published

Time in epoch seconds (may be filled with C<pubDate>, C<dc:date>, C<created>, C<issued>, C<updated> or C<modified>)

=head2  author

May be filled from C<author> or C<dc:creator>

=head2  tags

Optional - array ref of C<tags>, C<categories> or C<dc:subjects>.

=head2  enclosures

Optional - array ref of enclosures, each a hashref with the keys url, type and length.

=head2  feed

A reference to the feed this item belongs to. Note that this is a weak
reference, so it maybe undefined, if the parent feed is no longer in scope.

=head1 METHODS

L<Mojo::Feed::Item> inherits all methods from L<Mojo::Base> and adds the following ones:

=head2 to_hash

  my $hash = $item->to_hash;
  print $hash->{title};

Return a hash reference representing the item.

=head2 to_string

Return a XML serialized text of the item's Mojo::DOM node. Note that this can be different from the original XML text in the feed.

=head1 CREDITS

Dotan Dimet

Mario Domgoergen

=head1 LICENSE

Copyright (C) Dotan Dimet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Dotan Dimet E<lt>dotan@corky.netE<gt>

Mario Domgoergen

=cut
