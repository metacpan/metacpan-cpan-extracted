package Mojolicious::Plugin::FeedReader;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.09';
use Mojo::Util qw(decode trim);
use Mojo::File;
use Mojo::DOM;
use Mojo::IOLoop;
use HTTP::Date;
use Carp qw(carp croak);
use Scalar::Util qw(blessed);

our @time_fields
  = (qw(pubDate published created issued updated modified dc\:date));
our %is_time_field = map { $_ => 1 } @time_fields;

# feed mime-types:
our @feed_types = (
  'application/x.atom+xml', 'application/atom+xml',
  'application/xml',        'text/xml',
  'application/rss+xml',    'application/rdf+xml'
);
our %is_feed = map { $_ => 1 } @feed_types;

sub register {
  my ($self, $app) = @_;
  foreach my $method (
    qw( find_feeds parse_rss parse_opml ))
  {
    $app->helper($method => \&{$method});
  }
  $app->helper(parse_feed => \&parse_rss);
}

sub make_dom {
  my ($xml) = @_;
  my $rss;
  if (!ref $xml) {    # assume file
    $rss = Mojo::File->new($xml)->slurp;
    die "Unable to read file $xml: $!" unless ($rss);
  }
  elsif (ref $xml eq 'SCALAR') {    # assume string
    $rss = $$xml;
  }
  elsif (blessed $xml && $xml->isa('Mojo::DOM')) { # Mojo::DOM (old style)
    return $xml;
  }
  elsif (blessed $xml && $xml->can('slurp')) { # Mojo::Asset/File or similar
    $rss = $xml->slurp;
  }
  else {
    die "don't know how to make a Mojo::DOM from object $xml";
  }
  #my $rss_str = decode 'UTF-8', $rss;
  my $rss_str = $rss;
  die "Failed to read asset $xml (as UTF-8): $!" unless ($rss_str);
  return Mojo::DOM->new->parse($rss_str);
}

sub parse_rss {
  my ($c, $xml, $cb) = @_;
  if (blessed $xml && $xml->isa('Mojo::URL')) {
    # this is the only case where we might go non-blocking:
    if ($cb && ref $cb eq 'CODE') {
      return
      $c->ua->get(
        $xml,
        sub {
          my ($ua, $tx) = @_;
          my $feed;
          if ($tx->success) {
            my $body = $tx->res->body;
            my $dom = make_dom(\$body);
            eval { $feed = parse_rss_dom($dom); };
          }
          $c->$cb($feed);
        }
      );
    }
    else {
      my $tx = $c->ua->get($xml);
      if ($tx->success) {
        my $body = $tx->res->body;
        $xml = \$body;
      }
      else {
        croak "Error getting feed from url $xml: ", (($tx->error) ? $tx->error->{message} : '');
      }
    }
  }
  my $dom = make_dom($xml);
  return ($dom) ? parse_rss_dom($dom) : 1;
}

sub parse_rss_dom {
  my ($dom) = @_;
  die "Argument $dom is not a Mojo::DOM" unless ($dom->isa('Mojo::DOM'));
  my $feed    = parse_rss_channel($dom);    # Feed properties
  my $items   = $dom->find('item');
  my $entries = $dom->find('entry');               # Atom
  my $res     = [];
  foreach my $item ($items->each, $entries->each) {
    push @$res, parse_rss_item($item);
  }
  if (@$res) {
    $feed->{'items'} = $res;
  }
  return $feed;
}

sub parse_rss_channel {
  my ($dom) = @_;
  my %info;
  foreach my $k (
    qw{title subtitle description tagline link:not([rel]) link[rel=alternate] dc\:creator author webMaster},
    @time_fields
    )
  {
    my $p = $dom->at("channel > $k") || $dom->at("feed > $k");   # direct child
    if ($p) {
      $info{$k} = $p->text || $p->content || $p->attr('href');
      if ($k eq 'author' && $p->at('name')) {
         $info{$k} = $p->at('name')->text || $p->at('name')->content;
      }
      if ($is_time_field{$k}) {
        $info{$k} = str2time($info{$k});
      }
    }
  }
  my ($htmlUrl)
    = grep { defined $_ }
    map { delete $info{$_} } ('link:not([rel])', 'link[rel=alternate]');
  my ($description)
    = grep { defined $_ }
    map { exists $info{$_} ? $info{$_} : undef }
    (qw(description tagline subtitle));
  $info{htmlUrl}     = $htmlUrl     if ($htmlUrl);
  $info{description} = $description if ($description);

  # normalize fields:
  my @replace = (
    'pubDate'  => 'published',
    'dc\:date' => 'published',
    'created'  => 'published',
    'issued'   => 'published',
    'updated'  => 'published',
    'modified' => 'published',
    'dc\:creator' => 'author',
    'webMaster' => 'author'
  );
  while (my ($old, $new) = splice(@replace, 0, 2)) {
    if ($info{$old} && !$info{$new}) {
      $info{$new} = delete $info{$old};
    }
  }
  return (keys %info) ? \%info : undef;
}

sub parse_rss_item {
  my ($item) = @_;
  my %h;
  foreach my $k (
    qw(title id summary guid content description content\:encoded xhtml\:body dc\:creator author),
    @time_fields
    )
  {
    my $p = $item->at($k);
    if ($p) {

      # skip namespaced items - like itunes:summary - unless explicitly
      # searched:
      next
        if ($p->tag =~ /\:/
        && $k ne 'content\:encoded'
        && $k ne 'xhtml\:body'
        && $k ne 'dc\:date'
        && $k ne 'dc\:creator');
      $h{$k} = $p->text || $p->content;
      if ($k eq 'author' && $p->at('name')) {
        $h{$k} = $p->at('name')->text;
      }
      if ($is_time_field{$k}) {
        $h{$k} = str2time($h{$k});
      }
    }
  }

  # let's handle links seperately, because ATOM loves these buggers:
  $item->find('link')->each(
    sub {
      my $l = shift;
      if ($l->attr('href')) {
        if (!$l->attr('rel') || $l->attr('rel') eq 'alternate') {
          $h{'link'} = $l->attr('href');
        }
      }
      else {
        if ($l->text =~ /\w+/) {
          $h{'link'} = $l->text;    # simple link
        }

#         else { # we have an empty link element with no 'href'. :-(
#           $h{'link'} = $1 if ($l->next->text =~ m/^(http\S+)/);
#         }
      }
    }
  );

  # find tags:
  my @tags;
  $item->find('category, dc\:subject')
    ->each(sub { push @tags, $_[0]->text || $_[0]->attr('term') });
  if (@tags) {
    $h{'tags'} = \@tags;
  }
  #
  # normalize fields:
  my @replace = (
    'content\:encoded' => 'content',
    'xhtml\:body'      => 'content',
    'summary'          => 'description',
    'pubDate'          => 'published',
    'dc\:date'         => 'published',
    'created'          => 'published',
    'issued'           => 'published',
    'updated'          => 'published',
    'modified'         => 'published',
    'dc\:creator'      => 'author'

    #    'guid'             => 'link'
  );
  while (my ($old, $new) = splice(@replace, 0, 2)) {
    if ($h{$old} && !$h{$new}) {
      $h{$new} = delete $h{$old};
    }
  }
  my %copy = ('description' => 'content', link => 'id', guid => 'id');
  while (my ($fill, $required) = each %copy) {
    if ($h{$fill} && !$h{$required}) {
      $h{$required} = $h{$fill};
    }
  }
  $h{"_raw"} = $item->to_string;
  return \%h;
}

# find_feeds - get RSS/Atom feed URL from argument.
# Code adapted to use Mojolicious from Feed::Find by Benjamin Trott
# Any stupid mistakes are my own
sub find_feeds {
  my $self = shift;
  my $url  = shift;
  my $cb   = (ref $_[-1] eq 'CODE') ? pop @_ : undef;
#  $self->ua->max_redirects(5)->connect_timeout(30);
  my $main = sub {
    my ($tx) = @_;
    my @feeds;
#    if ($tx->success) { say $tx->res->code } else { say $tx->error };
    return unless ($tx->success && $tx->res->code == 200);
    eval { @feeds = _find_feed_links($self, $tx->req->url, $tx->res); };
    if ($@) {
      croak "Exception in find_feeds - ", $@;
    }
    return (@feeds);
  };
  if ($cb) {    # non-blocking:
    $self->ua->get(
      $url,
      sub {
        my ($ua, $tx) = @_;
        my (@feeds) = $main->($tx);
        $cb->(@feeds);
      }
    );
  }
  else {
    my $tx = $self->ua->get($url);
    return $main->($tx);
  }
}

sub _find_feed_links {
  my ($self, $url, $res) = @_;

  state $feed_ext = qr/\.(?:rss|xml|rdf)$/;
  my @feeds;

  # use split to remove charset attribute from content_type
  my ($content_type) = split(/[; ]+/, $res->headers->content_type);
  if ($is_feed{$content_type}) {
    push @feeds, Mojo::URL->new($url)->to_abs;
  }
  else {
    # we are in a web page. PHEAR.
    my $base = Mojo::URL->new(
      $res->dom->find('head base')->map('attr', 'href')->join('') || $url)->to_abs($url);
    my $title
      = $res->dom->find('head > title')->map('text')->join('') || $url;
    $res->dom->find('head link')->each(
      sub {
        my $attrs = $_->attr();
        return unless ($attrs->{'rel'});
        my %rel = map { $_ => 1 } split /\s+/, lc($attrs->{'rel'});
        my $type = ($attrs->{'type'}) ? lc trim $attrs->{'type'} : '';
        if ($is_feed{$type} && ($rel{'alternate'} || $rel{'service.feed'})) {
          push @feeds, Mojo::URL->new($attrs->{'href'})->to_abs($base);
        }
      }
    );
    $res->dom->find('a')->grep(
      sub {
        $_->attr('href')
          && Mojo::URL->new($_->attr('href'))->path =~ /$feed_ext/io;
      }
      )->each(
      sub {
        push @feeds, Mojo::URL->new($_->attr('href'))->to_abs($base);
      }
      );
    unless (@feeds)
    {    # call me crazy, but maybe this is just a feed served as HTML?
      my $body = $res->body;
      if ($self->parse_feed(\$body)) {
        push @feeds, Mojo::URL->new($url)->to_abs;
      }
    }
  }
  return @feeds;
}

sub parse_opml {
  my ($self, $opml_file) = @_;
  my $opml_str = decode 'UTF-8',
    (ref $opml_file) ? $opml_file->slurp : Mojo::File->new($opml_file)->slurp;
  my $d = Mojo::DOM->new->parse($opml_str);
  my (%subscriptions, %categories);
  for my $item ($d->find(q{outline})->each) {
    my $node = $item->attr;
    if (!defined $node->{xmlUrl}) {
      my $cat = $node->{title} || $node->{text};
      $categories{$cat} = $item->children('[xmlUrl]')->map('attr', 'xmlUrl');
    }
    else {    # file by RSS URL:
      $subscriptions{$node->{xmlUrl}} = $node;
    }
  }


  # assign categories
  for my $cat (keys %categories) {
    for my $rss ($categories{$cat}->each) {
      next unless ($subscriptions{$rss}); # don't auto-vivify for empty "categories"
      $subscriptions{$rss}{'categories'} ||= [];
      push @{$subscriptions{$rss}{'categories'}}, $cat;
    }
  }
  return (values %subscriptions);
}


1;

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::FeedReader - Mojolicious plugin to find and parse RSS & Atom feeds

=head1 SYNOPSIS

        # Mojolicious
         $self->plugin('FeedReader');

         # Mojolicious::Lite
         plugin 'FeedReader';

        # Blocking:
        get '/b' => sub {
          my $self = shift;
          my ($feed) = $self->find_feeds(q{search.cpan.org});
          my $out = $self->parse_feed($feed);
          $self->render(template => 'uploads', items => $out->{items});
        };

        # Non-blocking:
        get '/nb' => sub {
          my $self = shift;
          $self->render_later;
          my $delay = Mojo::IOLoop->delay(
            sub {
              $self->find_feeds("search.cpan.org", shift->begin(0));
            },
            sub {
              my $feed = pop;
              $self->parse_feed($feed, shift->begin);
            },
            sub {
                my $data = pop;
                $self->render(template => 'uploads', items => $data->{items});
            });
          $delay->wait unless Mojo::IOLoop->is_running;
        };

        app->start;

        __DATA__

        @@ uploads.html.ep
        <ul>
        % for my $item (@$items) {
          <li><%= link_to $item->{title} => $item->{link} %> - <%= $item->{description} %></li>
        % }
        </ul>

=head1 DESCRIPTION

B<Mojolicious::Plugin::FeedReader> implements minimalistic helpers for identifying,
fetching and parsing RSS and Atom Feeds.  It has minimal dependencies, relying as
much as possible on Mojolicious components - Mojo::UserAgent for fetching feeds and
checking URLs, Mojo::DOM for XML/HTML parsing.
It is therefore rather fragile and naive, and should be considered Experimental/Toy
code - B<use at your own risk>.


=head1 METHODS

L<Mojolicious::Plugin::FeedReader> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application. This method will install the helpers
listed below in your Mojolicious application.

=head1 HELPERS

B<Mojolicious::Plugin::FeedReader> implements the following helpers.

=head2 find_feeds

  # Call blocking
  my (@feeds) = app->find_feeds('search.cpan.org');
  # @feeds is a list of Mojo::URL objects

  # Call non-blocking
  $self->find_feeds('http://example.com', sub {
    my (@feeds) = @_;
    unless (@feeds) {
      $self->render_exception("no feeds found, " . $info->{error});
    }
    else {
      ....
    }
  });

A Mojolicious port of L<Feed::Find> by Benjamin Trott. This helper implements feed auto-discovery for finding syndication feeds, given a URI.
If given a callback function as an additional argument, execution will be non-blocking.

=head2 parse_feed

  # parse an RSS/Atom feed
  # blocking
  my $url = Mojo::URL->new('http://rss.slashdot.org/Slashdot/slashdot');
  my $feed = $self->parse_feed($url);
  for my $item (@{$feed->{items}}) {
    say $_ for ($item->{title}, $item->{description}, 'Tags: ' . join q{,}, @{$item->{tags}});
  }

  # non-blocking
  $self->parse_feed($url, sub {
    my ($c, $feed) = @_;
    $c->render(text => "Feed tagline: " . $feed->{tagline});
  });

  # parse a file
  $feed2 = $self->parse_feed('/downloads/foo.rss');

  # parse response
  $self->ua->get($feed_url, sub {
    my ($ua, $tx) = @_;
    my $feed = $self->parse_feed($tx->res);
  });

A minimalist liberal RSS/Atom parser, using Mojo::DOM queries.

Dates are parsed using L<HTTP::Date>.

If parsing fails (for example, the parser was given an HTML page), the helper will return undef.

On success, the result returned is a hashref with the following keys:

=over 4

=item * title

=item * description (may be filled from subtitle or tagline if absent)

=item * htmlUrl - web page URL associated with the feed

=item * items - array ref of feed news items

=item * subtitle (optional)

=item * tagline (optional)

=item * author (name of author field, or dc:creator or webMaster)

=item * published - time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)

=back

Each item in the items array is a hashref with the following keys:

=over 4

=item * title

=item * link

=item * content (may be filled with content:encoded, xhtml:body or description fields)

=item * id (will be equal to link or guid if it is undefined and either of those fields exists)

=item * description (optional) - usually a shorter form of the content (may be filled with summary if description is missing)

=item * guid (optional)

=item * published - time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)

=item * author (may be filled from author or dc:creator)

=item * tags (optional) - array ref of tags, categories or dc:subjects.

=item * _raw - XML serialized text of the item's Mojo::DOM node. Note that this can be different from the original XML text in the feed.

=back

=head2 parse_opml

  my @subscriptions = app->parse_opml( 'mysubs.opml' );
  foreach my $sub (@subscriptions) {
    say 'RSS URL is: ',     $sub->{xmlUrl};
    say 'Website URL is: ', $sub->{htmlUrl};
    say 'categories: ', join ',', @{$sub->{categories}};
  }

Parse an OPML subscriptions file and return the list of feeds as an array of hashrefs.

Each hashref will contain an array ref in the key 'categories' listing the folders (parent nodes) in the OPML tree the subscription item appears in.

=head1 CREDITS

Some tests adapted from L<Feed::Find> and L<XML:Feed> Feed autodiscovery adapted from L<Feed::Find>.

Test data (web pages, feeds and excerpts) included in this package is intended for testing purposes only, and is not meant in any way
to infringe on the rights of the respective authors.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Dotan Dimet.

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>

L<XML::Feed>, L<Feed::Find>, L<HTTP::Date>

=cut
