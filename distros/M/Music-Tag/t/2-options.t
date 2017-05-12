#!/usr/bin/perl -w
use strict;

use Test::More tests => 171;
use 5.006;

BEGIN { use_ok('Music::Tag') }

my $tag = Music::Tag->new(
    undef,
    {artist    => "Sarah Slean",
     album     => "Orphan Music",
     title     => "Mary",
     comment   => undef,            # Should be ignored for now.
     ANSIColor => 0,
     quiet     => 1,
     locale    => "ca"
    },
    "Option"
                         );

ok($tag,          'Object created');
ok($tag->get_tag, 'get_tag called');

cmp_ok($tag->artist,      'eq', 'Sarah Slean',  'artist');
cmp_ok($tag->album,       'eq', 'Orphan Music', 'album');
cmp_ok($tag->albumartist, 'eq', 'Sarah Slean',  'albumartist');

ok(!defined $tag->comment, 'comment should be undefined');

ok($tag->encoded_by('Sarah'), 'Set encoded_by');
cmp_ok($tag->encoded_by, 'eq', 'Sarah', 'Get encoded_by');
$tag->albumtags('Canada,Female,Bible Reference');
cmp_ok($tag->albumtags->[2], 'eq', 'Bible Reference', 'albumtags');
$tag->artisttags(['Canada', 'Female']);
cmp_ok($tag->artisttags->[1], 'eq', 'Female', 'artisttags');

ok($tag->countrycode('CA'), 'Set Country Code');
cmp_ok($tag->countrycode, 'eq', 'CA', 'Get Country Code');
ok(length($tag->country) > 4, 'country from code');

ok($tag->discnum('2/3'), 'Set discnum');
cmp_ok($tag->disc,       '==', 2, 'Get discnum');
cmp_ok($tag->totaldiscs, '==', 3, 'Get totaldiscs');

ok($tag->track(4),        'Set track');
ok($tag->totaltracks(40), 'Set total tracks');
cmp_ok($tag->tracknum, 'eq', '4/40', 'Get tracknum');

ok($tag->ean('0825646392322'), 'Set ean');
cmp_ok($tag->upc, 'eq', '825646392322', 'Get upc');

ok($tag->releasetime('2006-10-31 1:01:02'), 'Set releasetime');
cmp_ok($tag->releasedate, 'eq', '2006-10-31', 'releasedate');

ok($tag->datamethods('testit'), 'add custom method');
ok($tag->testit('blue'),        'write to custom method');
cmp_ok($tag->testit, 'eq', 'blue', 'read custom method');

foreach my $meth (
    qw(album album_type albumartist albumartist_sortname albumid appleid artist artist_type artistid asin bitrate booklet codec comment compilation composer copyright disctitle encoded_by encoder genre ipod ipod_dbid ipod_location ipod_trackid label lyrics mb_albumid mb_artistid mb_trackid mip_puid originalartist path sortname  title  url user filetype mip_fingerprint)
  ) {
    my $val = "test" . $meth . int(rand(1000));
    ok($tag->$meth($val), 'auto write to ' . $meth);
    cmp_ok($tag->$meth, 'eq', $val, 'auto read from ' . $meth);
}

foreach my $meth (
    qw( bytes disc duration frames framesize frequency gaplessdata playcount postgap pregap rating albumrating  samplecount secs stereo tempo totaldiscs totaltracks )
  ) {
    my $val = int(rand(10))+1;
    ok($tag->$meth($val), 'auto write to ' . $meth);
    cmp_ok($tag->$meth, '==', $val, 'auto read from ' . $meth);
}

my %values = ();

foreach my $meth (
	 qw(artist_end_epoch artist_start_epoch lastplayedepoch mepoch recordepoch releaseepoch)) {
	 my $val = int(rand(1_800_000_000));
	 $values{$meth} = $val;
	 ok($tag->$meth($val), 'auto write to '. $meth);
	 cmp_ok($tag->$meth, '==', $val, 'auto read from' . $meth);
}

foreach my $meth (
	 qw(artist_end_date artist_start_date lastplayeddate mdate recorddate releasedate)) {
	 my $me = $meth;
	 my $md = $meth;
	 $me =~ s/date/epoch/;
	 $md =~ s/_date//;
	 my @tm = gmtime($values{$me});
	 cmp_ok($tag->$md, 'eq', sprintf('%04d-%02d-%02d', $tm[5]+1900, $tm[4]+1, $tm[3]), 'auto read from '. $md);
}

foreach my $meth (
	 qw(artist_end_time artist_start_time lastplayedtime mtime recordtime releasetime)) {
	 my $me = $meth;
	 $me =~ s/time/epoch/;
	 my @tm = gmtime($values{$me});
	 cmp_ok($tag->$meth, 'eq', sprintf('%04d-%02d-%02d %02d:%02d:%02d', $tm[5]+1900, $tm[4]+1, $tm[3], $tm[2], $tm[1], $tm[0]), 'auto read from '. $meth);
}

foreach my $meth (qw(recorddate releasedate)) {
    ok($tag->$meth('2009-07-12'), 'auto write to ' . $meth);
    cmp_ok($tag->$meth, 'eq', '2009-07-12', 'auto read from' . $meth);
}

ok(!$tag->setfileinfo, 'setfileinfo should fail');
ok(!$tag->sha1,        'sha1 should fail');

