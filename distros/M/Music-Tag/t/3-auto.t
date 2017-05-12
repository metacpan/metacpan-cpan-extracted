#!/usr/bin/perl -w
use strict;

use Test::More tests => 13;
use 5.006;

BEGIN { use_ok('Music::Tag') }

my $tag = Music::Tag->new('t/fake.music',
                          {autoplugin =>
                             {music => 'Option', 'nothing' => 'Option'},
                           artist    => "Sarah Slean",
                           album     => "Orphan Music",
                           title     => "Mary",
                           ANSIColor => 0,
                           quiet     => 1,
                           locale    => "ca"
                          },
                          "Auto"
                         );

ok($tag,          'Object created');
ok($tag->get_tag, 'get_tag called');

cmp_ok($tag->artist,      'eq', 'Sarah Slean',  'artist');
cmp_ok($tag->album,       'eq', 'Orphan Music', 'album');
cmp_ok($tag->albumartist, 'eq', 'Sarah Slean',  'albumartist');
ok($tag->encoded_by('Sarah'), 'Set encoded_by');
cmp_ok($tag->encoded_by, 'eq', 'Sarah', 'Get encoded_by');
$tag->albumtags('Canada,Female,Bible Reference');
cmp_ok($tag->albumtags->[2], 'eq', 'Bible Reference', 'albumtags');
$tag->artisttags(['Canada', 'Female']);
cmp_ok($tag->artisttags->[1], 'eq', 'Female', 'artisttags');

my $tag2 = Music::Tag->new('t/fake.music');

ok($tag2, 'Object defined');

ok($tag2->setfileinfo, 'setfileinfo');
cmp_ok($tag2->bytes, '==', 26, 'byte size');
