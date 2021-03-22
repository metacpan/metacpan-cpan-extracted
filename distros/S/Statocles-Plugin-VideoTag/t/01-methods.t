#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use Statocles::Test qw(build_test_site);

use_ok 'Statocles::Plugin::VideoTag';

my $plugin = new_ok 'Statocles::Plugin::VideoTag' => [ file_type => 'ogg' ];

my $site = build_test_site();

my $page = Statocles::Page::Plain->new(
    path    => 'test.html',
    site    => $site,
    content => '<p><a href="test.ogg">test.ogg</a></p>',
);

my $got = $plugin->video_tag($page);
like $got->dom, qr|<p><video controls><source src="test\.ogg" type="video/ogg"></video></p>|, 'video_tag';

$plugin = new_ok 'Statocles::Plugin::VideoTag' => [ file_type => 'youtu' ];

$page = Statocles::Page::Plain->new(
    path    => 'test.html',
    site    => $site,
    content => '<p><a href="https://www.youtube.com/watch?v=S1jo0uEs3zc">test</a></p>',
);

$got = $plugin->video_tag($page);
like $got->dom, qr|https://www.youtube.com/embed/|, 'video_tag';

done_testing();
