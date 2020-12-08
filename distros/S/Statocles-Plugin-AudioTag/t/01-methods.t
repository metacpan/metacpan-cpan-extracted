#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use Statocles::Test qw(build_test_site);

use_ok 'Statocles::Plugin::AudioTag';

new_ok 'Statocles::Plugin::AudioTag';

my $plugin = new_ok 'Statocles::Plugin::AudioTag' => [ file_type => 'ogg' ];

my $site = build_test_site();
my $page = Statocles::Page::Plain->new(
    path    => 'test.html',
    site    => $site,
    content => '<p><a href="test.ogg">test.ogg</a></p>',
);

my $got = $plugin->audio_tag($page);
like $got->dom, qr|<p><audio controls><source src="test\.ogg" type="audio/ogg"></audio></p>|, 'audio_tag';

done_testing();
