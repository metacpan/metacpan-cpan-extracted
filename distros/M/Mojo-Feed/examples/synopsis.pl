#!/usr/bin/env perl

use Mojolicious::Lite;

# Mojolicious::Lite
plugin 'FeedReader';

  my ($feed) = app->find_feeds(q{https://metacpan.org/});
  app->log->info("(Pre) Found $feed");
# Blocking:
get '/b' => sub {
  my $self = shift;
  my ($feed) = $self->find_feeds(q{https://metacpan.org/});
  app->log->info("Found $feed");
  my $out = $self->parse_feed($feed);
  app->log->info("Got $out");
  $self->render(template => 'uploads', items => $out->{items});
};

# Non-blocking:
get '/nb' => sub {
  my $self = shift;
  $self->render_later;
  $self->find_feeds("https://metacpan.org/",
      sub {
      my $feed = pop;
      app->log->info("Found $feed");
      $self->parse_feed($feed,
      sub {
        my $data = pop;
        $self->render(template => 'uploads', items => $data->{items});
        });
      });
};

app->start;

__DATA__

@@ uploads.html.ep
<h1>CPAN Recent Uploads</h1>
<ul>
% for my $item (@$items) {
  <li><%= link_to $item->{title} => $item->{link} %> - <%= $item->{description} %></li>
    % }
    </ul>

