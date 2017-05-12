#!/usr/bin/env perl
use strict;
use warnings;

use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use Mojo::ByteStream ('b');
use Mojo::Headers;
use lib '../lib';

use_ok('Mojolicious::Plugin::PubSubHubbub');

my $t = Test::Mojo->new;
my $app = $t->app;

$app->plugin('PubSubHubbub');

my $headers = Mojo::Headers->new;
$headers->parse(<<'LINKS');
Link: <http://example.com/TheBook/chapter2>; rel="previous";
         title="previous chapter"
Link: </>; rel="http://example.net/foo"
Link: </TheBook/chapter2>;
         rel="previous"; title*=UTF-8'de'letztes%20Kapitel,
         </TheBook/chapter4>;
         rel="next"; title*=UTF-8'de'n%c3%a4chstes%20Kapitel
Link: <http://example.org/>;
             rel="start http://example.net/relation/other"
Link: <http://pubsubhubbub.appspot.com/>;
             rel="hub"
Link: <http://sojolicio.us/feed.xml>;
             rel="self"
Link: <http://sojolicio.us/feed/comment.atom>;
             rel="alternate";
             type="application/atom+xml";
             title="Feed Comments"
Link: <http://sojolicio.us/feed.rss>;
             rel="alternate";
             type="application/rss+xml";
             title="Feeds"
Link: <http://sojolicio.us/feed.rdf>;
             rel="alternate";
             type="application/rdf+xml";
             title="Feeds"
Link: <http://sojolicio.us/feed.atom>;
             rel="alternate";
             type="application/atom+xml";
             title="Feeds"
Link: <http://sojolicio.us/feed/comments.rss>;
             rel="alternate";
             title="Feeds Comments"

LINKS

ok(my $links = Mojolicious::Plugin::PubSubHubbub::_discover_header_links($headers), 'Discover from head');

is($links->{hub}->[0]->{href}, 'http://pubsubhubbub.appspot.com/', 'Found hub');
is($links->{self}->[0]->{href}, 'http://sojolicio.us/feed.xml', 'Found feed');

my $alt = $links->{alternate};
is($alt->[0]->{href}, 'http://sojolicio.us/feed/comment.atom', 'Found alternate');
is($alt->[0]->{short_type}, 'atom', 'Found alternate');
is($alt->[0]->{title}, 'Feed Comments', 'Found alternate');
is($alt->[0]->{type}, 'application/atom+xml', 'Found alternate');

is($alt->[1]->{href}, 'http://sojolicio.us/feed.rss', 'Found alternate');
is($alt->[1]->{short_type}, 'rss', 'Found alternate');
is($alt->[1]->{title}, 'Feeds', 'Found alternate');
is($alt->[1]->{type}, 'application/rss+xml', 'Found alternate');

is($alt->[2]->{href}, 'http://sojolicio.us/feed.rdf', 'Found alternate');
is($alt->[2]->{short_type}, 'rdf', 'Found alternate');
is($alt->[2]->{title}, 'Feeds', 'Found alternate');
is($alt->[2]->{type}, 'application/rdf+xml', 'Found alternate');

is($alt->[3]->{href}, 'http://sojolicio.us/feed.atom', 'Found alternate');
is($alt->[3]->{short_type}, 'atom', 'Found alternate');
is($alt->[3]->{title}, 'Feeds', 'Found alternate');
is($alt->[3]->{type}, 'application/atom+xml', 'Found alternate');

is($alt->[4]->{href}, 'http://sojolicio.us/feed/comments.rss', 'Found alternate');
is($alt->[4]->{short_type}, 'rss', 'Found alternate');
is($alt->[4]->{title}, 'Feeds Comments', 'Found alternate');
ok(!$alt->[4]->{type}, 'Found alternate');

my ($topic, $hub) = Mojolicious::Plugin::PubSubHubbub::_discover_sort_links($links);

is($topic->{href}, 'http://sojolicio.us/feed.xml', 'Found topic');
is($hub->{href}, 'http://pubsubhubbub.appspot.com/', 'Found hub');


my $dom = Mojo::DOM->new(<<'DOM');
<!DOCTYPE html>
<head>
  <link href="http://example.com/TheBook/chapter2" rel="previous"
        title="previous chapter" />
  <link href="/" rel="http://example.net/foo" />
  <link href="/TheBook/chapter2"
         rel="previous">
  <link href="/TheBook/chapter4"
         rel="next">
  <link href="http://example.org/"
             rel="start http://example.net/relation/other" />
  <link href="http://pubsubhubbub.appspot.com/"
             rel="hub">
  <link href="http://sojolicio.us/feed.xml"
             rel="self" />
  <title>Versuch</title>
  <link href="http://sojolicio.us/feed/comment.atom"
             rel="alternate"
             type="application/atom+xml"
             title="Feed Comments">
  <link href="http://sojolicio.us/feed.rss"
             rel="alternate"
             type="application/rss+xml"
             title="Feeds">
  <link href="http://sojolicio.us/feed.rdf"
             rel="alternate"
             type="application/rdf+xml"
             title="Feeds" />
  <link href="http://sojolicio.us/feed.atom"
             rel="alternate"
             type="application/atom+xml"
             title="Feeds">
  <link href="http://sojolicio.us/feed/comments.rss"
             rel="alternate"
             title="Feeds Comments">
</head>
<body>
  <h1>Test</h1>
</body>
DOM

ok($links = Mojolicious::Plugin::PubSubHubbub::_discover_dom_links($dom), 'Discover from dom');

is($links->{hub}->[0]->{href}, 'http://pubsubhubbub.appspot.com/', 'Found hub');
is($links->{self}->[0]->{href}, 'http://sojolicio.us/feed.xml', 'Found feed');

$alt = $links->{alternate};
is($alt->[0]->{href}, 'http://sojolicio.us/feed/comment.atom', 'Found alternate');
is($alt->[0]->{short_type}, 'atom', 'Found alternate');
is($alt->[0]->{title}, 'Feed Comments', 'Found alternate');
is($alt->[0]->{type}, 'application/atom+xml', 'Found alternate');

is($alt->[1]->{href}, 'http://sojolicio.us/feed.rss', 'Found alternate');
is($alt->[1]->{short_type}, 'rss', 'Found alternate');
is($alt->[1]->{title}, 'Feeds', 'Found alternate');
is($alt->[1]->{type}, 'application/rss+xml', 'Found alternate');

is($alt->[2]->{href}, 'http://sojolicio.us/feed.rdf', 'Found alternate');
is($alt->[2]->{short_type}, 'rdf', 'Found alternate');
is($alt->[2]->{title}, 'Feeds', 'Found alternate');
is($alt->[2]->{type}, 'application/rdf+xml', 'Found alternate');

is($alt->[3]->{href}, 'http://sojolicio.us/feed.atom', 'Found alternate');
is($alt->[3]->{short_type}, 'atom', 'Found alternate');
is($alt->[3]->{title}, 'Feeds', 'Found alternate');
is($alt->[3]->{type}, 'application/atom+xml', 'Found alternate');

is($alt->[4]->{href}, 'http://sojolicio.us/feed/comments.rss', 'Found alternate');
is($alt->[4]->{short_type}, 'rss', 'Found alternate');
is($alt->[4]->{title}, 'Feeds Comments', 'Found alternate');
ok(!$alt->[4]->{type}, 'Found alternate');

($topic, $hub) = Mojolicious::Plugin::PubSubHubbub::_discover_sort_links($links);

is($topic->{href}, 'http://sojolicio.us/feed.xml', 'Found topic');
is($hub->{href}, 'http://pubsubhubbub.appspot.com/', 'Found hub');


$dom = Mojo::DOM->new(<<'DOM');
<!DOCTYPE html>
<head>
  <link href="http://example.com/TheBook/chapter2" rel="previous"
        title="previous chapter" />
  <link href="/" rel="http://example.net/foo" />
  <link href="/TheBook/chapter2"
         rel="previous">
  <link href="/TheBook/chapter4"
         rel="next">
  <link href="http://example.org/"
             rel="start http://example.net/relation/other" />
  <link href="http://pubsubhubbub.appspot.com/"
             rel="hub">
  <title>Versuch</title>
  <link href="http://sojolicio.us/feed/comment.atom"
             rel="alternate"
             type="application/atom+xml"
             title="Feed Comments">
  <link href="http://sojolicio.us/feed.rss"
             rel="alternate"
             type="application/rss+xml"
             title="Feeds">
  <link href="http://sojolicio.us/feed.rdf"
             rel="alternate"
             type="application/rdf+xml"
             title="Feeds" />
  <link href="http://sojolicio.us/feed.atom"
             rel="alternate"
             type="application/atom+xml"
             title="Feeds">
  <link href="http://sojolicio.us/feed/comments.rss"
             rel="alternate"
             title="Feeds Comments">
</head>
<body>
  <h1>Test</h1>
</body>
DOM

ok($links = Mojolicious::Plugin::PubSubHubbub::_discover_dom_links($dom), 'Discover from dom');

($topic, $hub) = Mojolicious::Plugin::PubSubHubbub::_discover_sort_links($links);

is($topic->{href}, 'http://sojolicio.us/feed.atom', 'Found topic');
is($hub->{href}, 'http://pubsubhubbub.appspot.com/', 'Found hub');

# No test
# ($topic, $hub) = $app->pubsub_discover('https://push-pub.appspot.com/');
# diag $topic;
# diag $hub;

done_testing;
