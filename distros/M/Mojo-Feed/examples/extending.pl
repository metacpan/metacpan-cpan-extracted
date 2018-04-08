#!/usr/bin/env perl

use Mojo::Base -strict;

use Mojo::Feed;
use Mojo::Util qw(decode);
use Mojo::File qw(path);

package Mojo::Feed::Role::FeedType;
use Mojo::Base -role;

has feed_type => sub {
  my $top     = shift->dom->children->first;
  my $tag     = $top->tag;
  my $version = $top->attr('version');
  return
      ($tag =~ /feed/i) ? 'atom'
    : ($tag =~ /rss/i)  ? 'rss ' . $version
    : ($tag =~ /rdf/i)  ? 'rss 1.0'
    :                     'unknown';
};

package main;

my $cls = Mojo::Feed->with_roles("+FeedType");

for my $file (path(q{t/samples})->list()->grep(sub { "$_" =~ /xml$/ })->each) {
  my $body = decode 'UTF-8', $file->slurp;
  my $feed = $cls->new(body => $body, source => $file->basename);
  say $feed->source, "\t", $feed->feed_type;
}
