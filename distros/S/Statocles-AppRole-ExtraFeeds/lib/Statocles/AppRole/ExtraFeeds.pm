use 5.006;    # our
use strict;
use warnings;

package Statocles::AppRole::ExtraFeeds;

our $VERSION = '0.001003';

# ABSTRACT: Generate additional feed sets for apps

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo::Role qw( has around );
use Carp qw( croak );
use Statocles::App 0.070 ();    # 0.70 required for ->template
use Statocles::Page::List ();
use namespace::autoclean;

has 'extra_feeds' => (
  is      => 'ro',
  lazy    => 1,
  default => sub { {} },
);





use constant PATH_INDEX_PREFIX   => qr{  \A (.*) / index    [.](\w+) \z}sx;
use constant PATH_GENERIC_PREFIX => qr{  \A (.*) / ([^/.]+) [.](\w+) \z}sx;

# This separation is to help Coverage tools not lie to me that I did a perfect job
around pages => \&_around_pages;

sub _around_pages {
  my ( $orig, $self, @rest ) = @_;
  my (@pages) = $self->$orig(@rest);

  return @pages unless @pages;

  my %feed_cache;

  my @out_pages;

  while (@pages) {
    my $page = shift @pages;

    push @out_pages, $page;

    my (@existing_feeds) = $page->links('feed');

    next if not @existing_feeds;

    for my $feed_id ( sort keys %{ $self->extra_feeds } ) {
      my $feed = $self->extra_feeds->{$feed_id};
      my $feed_path;

      {
        my $reference_path = $existing_feeds[0]->href;
        my $feed_suffix = $feed->{name} || $feed_id;

        if ( $reference_path =~ PATH_INDEX_PREFIX ) {
          $feed_path = "$1/$feed_suffix";
        }
        elsif ( $reference_path =~ PATH_GENERIC_PREFIX ) {
          $feed_path = "$1/$2.$feed_suffix";
        }
        else {
          croak "Don't know how to derive feed path from $reference_path for $feed_suffix";
        }
      }

      if ( not exists $feed_cache{$feed_path} ) {
        my $feed_page = $feed_cache{$feed_path}{feed_page} = Statocles::Page::List->new(
          app      => $self,
          pages    => $page->pages,
          path     => $feed_path,
          template => $self->template( $feed->{template} || $feed->{name} || $feed_id ),
          links    => {
            alternate => [
              $self->link(
                href  => $page->path,
                title => ( $feed->{'index_title'} || $page->title || 'Web Index' ),
                type  => $page->type,
              ),
            ],
          },
        );

        $feed_cache{$feed_path}{feed_link} = $self->link(
          text => $feed->{text},
          href => $feed_page->path->stringify,
          type => $feed_page->type,
        );
      }
      $page->links( feed => $feed_cache{$feed_path}{feed_link} );
    }
  }
  return @out_pages, map { $feed_cache{$_}{feed_page} } sort keys %feed_cache;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::AppRole::ExtraFeeds - Generate additional feed sets for apps

=head1 VERSION

version 0.001003

=head1 EXPERIMENTAL

This module is very new and it comes with the following present caveats:

=over 4

=item * Application outside C<Statocles::App::Blog> untested.

Feedback welcome though, and it might work by magic!

=item * Implementation details a bit sketchy

The code works. I kinda feel like it shouldn't, and its like I've performed some magic
trick and the gods have smiled on me for a moment.

=item * You're on your own with templates

This at present is a glorified lump of glue on top of existing C<Statocles> behavior.

As such, if you want this to work, you'll probably want to copy some templates and modify them.

This module does nothing for you in terms of the actual formatting, it just pumps the right
glue so that the same code that generates the existing feeds will be invoked a few more times
but with the file names and templates you chose ( instead of the ones provided by default by the app )

Basically, you're going to want to copy C<blog/index.rss.ep> to C<blog/fulltext.rss.ep> and tweak
it a bit, or something.

=back

=head1 DESCRIPTION

This module is a role that can be applied to any C<Statocles::App> in a C<Statocles>'s C<Beam::Wire>
configuration.

  ...
  blog_app:
    class: 'Statocles::App::Blog'
    with: 'Statocles::AppRole::ExtraFeeds'
    args:
      url_root: '/blog'
      # ... more Statocles::App::Blog args
      extra_feeds:
        fulltext.rss:
          text: "RSS FullText"

This example creates a feed called C</blog/fulltext.rss> containing the contents of C<theme/blog/fulltext.rss.ep>
after template application, and is linked from every C<index> listing.

It also creates a feed called C<< /blog/tag/<%= tagname %>.fulltext.rss >> for each tag, provisioned from the same template.

=for Pod::Coverage PATH_INDEX_PREFIX PATH_GENERIC_PREFIX

=head1 PARAMETERS

=head2 C<extra_feeds>

This Role provides one tunable parameter on its applied class, C<extra_feeds>, which contains a
mapping of

  id => spec

=head3 C<extra_feeds> spec.

  {
    text      => required
    name      => default( id )
    template  => default( id )
  }

=head4 C<text>

This is the name of the feed when shown in links on both C<index> and C<tag index> pages.

=head4 C<template>

This is the name of the template to render the feeds content into.

Defaults to taking the same value as the key in the C<extra_fields> hash.

=head4 C<name>

This is the name of the file/file suffix that is generated.

It defaults to the same value as the key in the C<extra_feeds>
hash.

So:

  extra_feeds:
    fulltext.rss:
      text: "My FullText RSS"

And

  extra_feeds:
    genericlabel:
      text: "My FullText RSS"
      name: 'fulltext.rss'      # output name
      template: 'fulltext.rss'  # source template

Should both generate the same result.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
