#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 9;

use Music::Lyrics::LRC;

our $VERSION = '0.11';

my $lrc = Music::Lyrics::LRC->new();
ok( defined $lrc, 'constructed' );

my $pkg = 'Music::Lyrics::LRC';
isa_ok( $lrc, $pkg );

can_ok(
    $lrc, qw(
      lyrics
      tags
      add_lyric
      set_tag
      unset_tag
      load
      save
      _min_sec_to_msec
      _msec_to_min_sec
      ),
);

ok( $lrc->add_lyric( 0,  'lalala' ), 'add_lyric_0' );
ok( $lrc->add_lyric( 10, 'doremi' ), 'add_lyric_10' );

ok( my $lyrics = $lrc->lyrics, 'get_lyrics' );
ok( @{$lyrics} == 2, 'lyrics_count' );

ok( $lrc->set_tag( 'foo', 'bar' ), 'set_tag' );
ok( $lrc->unset_tag('foo'), 'unset_tag' );
