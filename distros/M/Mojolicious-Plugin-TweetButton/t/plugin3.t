#!/usr/bin/env perl

use strict;
use warnings;

#use utf8;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

# Silence
app->log->level('error');

plugin 'tweet_button' => {
    related => 'test',
};

get '/' => 'index';

my $t = Test::Mojo->new;

$t->get_ok('/')->content_is(<<'EOF');
<a href="http://twitter.com/share" class="twitter-share-button" data-count="vertical" data-related="test">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
<a href="http://twitter.com/share" class="twitter-share-button" data-count="horizontal" data-related="test">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
<a href="http://twitter.com/share" class="twitter-share-button" data-count="none" data-related="test">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
<a href="http://twitter.com/share" class="twitter-share-button" data-text="Foo" data-count="vertical" data-related="test">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
<a href="http://twitter.com/share" class="twitter-share-button" data-url="http://example.com" data-count="vertical" data-related="test">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
<a href="http://twitter.com/share" class="twitter-share-button" data-count="vertical" data-related="test" data-lang="fr">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
<a href="http://twitter.com/share" class="twitter-share-button" data-count="vertical" data-via="vtivti" data-related="test">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
<a href="http://twitter.com/share" class="twitter-share-button" data-count="vertical" data-related="kraih:A good guy!">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
EOF

done_testing();

__DATA__

@@ index.html.ep
<%= tweet_button =%>
<%= tweet_button count => 'horizontal' =%>
<%= tweet_button count => 'none' =%>
<%= tweet_button text => 'Foo' =%>
<%= tweet_button url => 'http://example.com' =%>
<%= tweet_button lang => 'fr' =%>
<%= tweet_button via => 'vtivti' =%>
<%= tweet_button related => 'kraih:A good guy!' =%>
