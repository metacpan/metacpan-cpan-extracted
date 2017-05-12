#!/usr/bin/env perl

use Mojolicious::Lite;
use FindBin;
use lib $FindBin::Bin . '/../lib';
# Mojolicious::Lite
plugin 'FeedReader';

# Blocking:
get '/b' => sub {
  my $self = shift;
  my ($feed) = $self->find_feeds(q{search.cpan.org});
  my $out = $self->parse_rss($feed);
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
      $self->parse_rss($feed, shift->begin);
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


