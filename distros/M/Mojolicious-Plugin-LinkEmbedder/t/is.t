use warnings;
use strict;
use Test::More;
use Module::Find;

Module::Find::useall('Mojolicious::Plugin::LinkEmbedder');

ok !Mojolicious::Plugin::LinkEmbedder::Link->is('foo'),                          'link is nothing';
ok Mojolicious::Plugin::LinkEmbedder::Link::Image->is('image'),                  'image';
ok Mojolicious::Plugin::LinkEmbedder::Link::Video->is('video'),                  'video';
ok Mojolicious::Plugin::LinkEmbedder::Link::Video::Youtube->is('video-youtube'), 'video-youtube';

done_testing;
