#!/usr/bin/env perl

use strict;
use warnings;
use Mojolicious::Lite;
use Test::Mojo;
use Test::More tests => 8;
use FindBin '$Bin';
use lib "$Bin/../lib";

plugin RelativeUrlFor => { replace_url_for => 1 };

get '/foo/bar/baz' => sub {
    my $self = shift;
    $self->stash(
        rel_url_for => $self->rel_url_for('/foo/a'),
        url_for     => $self->url_for('/foo/b'),
    );
} => 'foo';

# create tester
my $t = Test::Mojo->new;

$t->get_ok('/foo/bar/baz')->status_is(200)
  ->text_is('#rel_url_for',     '../a')
  ->text_is('#url_for',         '../b')
  ->text_is('#ren_rel_url_for', '../c')
  ->text_is('#ren_url_for',     '../d');
is($t->tx->res->dom->at('#link_to a')->attr('href'), '../e', 'link_to');
is($t->tx->res->dom->at('#form_for')->attr('action'), '../f', 'form_for');

__DATA__
@@foo.html.ep
<p id="rel_url_for"><%= $rel_url_for %></p>
<p id="url_for"><%= $url_for %></p>
<p id="ren_rel_url_for"><%= rel_url_for '/foo/c' %></p>
<p id="ren_url_for"><%= url_for '/foo/d' %></p>
<p id="link_to"><%= link_to link => '/foo/e' %></p>
<%= form_for '/foo/f' => (id => 'form_for') %>
