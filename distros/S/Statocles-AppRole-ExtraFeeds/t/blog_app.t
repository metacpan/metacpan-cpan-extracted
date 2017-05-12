use strict;
use warnings;

use Test::More;

use Scalar::Util    ('blessed');
use Data::Dump      ('pp');
use Term::ANSIColor ('colored');
use Path::Tiny      ( 'path', 'tempdir' );
use Statocles::Test ('build_test_site');

use Test::Deep ();    # statocles needs this installed, but something can fubar in deps
                      # on travis leading to a "no Test::Deep" ... somehow. IDK
use Beam::Wire 1.016 ();    # :with works
use Statocles::App::Blog           ();
use Statocles::AppRole::ExtraFeeds ();

use lib 't/lib';
use KENTNL::Utils ( 'symdump', 'has_feeds' );

# SETUP

my $wd = tempdir();
$wd->child('theme/blog')->mkpath;
$wd->child('theme/site')->mkpath;
$wd->child('theme/layout')->mkpath;
$wd->child('blog/2014/04/02')->mkpath;
$wd->child('blog/2014/04/02/a.markdown')->spew_raw(<<'BLOG_A');
---
date: 2014-04-02 01:02:03
tags: [ 'atag' ]
---
BLOG_A
$wd->child('blog/2014/04/02/b.markdown')->spew_raw(<<'BLOG_B');
---
date: 2014-04-02 01:04:06
tags: [ 'atag' ]
---
BLOG_B
$wd->child('theme/blog/index.html.ep')->spew_raw('');
$wd->child('theme/blog/post.html.ep')->spew_raw('');
$wd->child('theme/blog/index.atom.ep')->spew_raw('');
$wd->child('theme/blog/index.rss.ep')->spew_raw('');
$wd->child('theme/blog/fulltext.rss.ep')->spew_raw('');
$wd->child('theme/layout/default.html.ep')->spew_raw(<<'EOF');
title: <%= $self->title %>
site_title: <%= $site->title %>
links:
% for my $link ( $site->nav('main') ) {
  - href: <%= $link->href %>
    title: <%= $link->title %>
    text: <%= $link->text %>
% }
content: <<
  <%= $content %>
EOF

my $site = build_test_site(
  theme    => $wd->child('theme'),
  base_url => 'http://www.example.org',
);

my $beamer  = Beam::Wire->new();
my $service = $beamer->create_service(
  blog => (
    'class' => 'Statocles::App::Blog',
    'with'  => 'Statocles::AppRole::ExtraFeeds',
    'args'  => {
      url_root    => '/blog',
      store       => $wd->child('blog'),
      site        => $site,
      extra_feeds => {
        'fulltext.rss' => { text => 'RSS FullText' },
      },
    },
  ),
);

ok( $service->can('extra_feeds'), "Composed service can -> extra_feeds ( composition check )" ) or do {
  diag "Service Lacks composed method 'extra_feeds'. So Roles are broken";
  diag pp $service;
  diag symdump( blessed($service) );
};
$service->can('extra_feeds') and note explain { config => $service->extra_feeds };

my %pagemap = (
  '/blog/index.html' => sub {
    has_feeds( $_->path, $_, qw( /blog/index.atom /blog/index.rss /blog/fulltext.rss ) );
  },
  '/blog/index.atom' => sub {
    has_feeds( $_->path, $_, () );
  },
  '/blog/index.rss' => sub {
    has_feeds( $_->path, $_, () );
  },
  '/blog/fulltext.rss' => sub {
    has_feeds( $_->path, $_, () );
  },
  '/blog/2014/04/02/b.html' => sub {
    has_feeds( $_->path, $_, () );
  },
  '/blog/2014/04/02/a.html' => sub {
    has_feeds( $_->path, $_, () );
  },
  '/blog/tag/atag/index.html' => sub {
    has_feeds( $_->path, $_, qw( /blog/tag/atag.atom /blog/tag/atag.rss /blog/tag/atag.fulltext.rss ) );
  },
  '/blog/tag/atag.rss' => sub {
    has_feeds( $_->path, $_, () );
  },
  '/blog/tag/atag.fulltext.rss' => sub {
    has_feeds( $_->path, $_, () );
  },
  '/blog/tag/atag.atom' => sub {
    has_feeds( $_->path, $_, () );
  },
);
for my $page ( $service->pages ) {
  my $path = $page->path;
  if ( !$pagemap{$path} ) {
    fail("Unexpected page $path");
    next;
  }
  my $test = delete $pagemap{$path};
  note( "Page: " . colored( ['yellow'], $path ) );
  note( "Page Class: " . colored( ['yellow'], blessed($page) ) );
  note( "Links: " . colored( ['yellow'], pp $page->_links ) );
  local $_ = $page;
  local $@;
  eval { $test->($page); 1 } or fail("Exception occurred in $path tests"), diag $@;
}
for ( keys %pagemap ) {
  fail("Expected page $_ missing");
}

done_testing;

