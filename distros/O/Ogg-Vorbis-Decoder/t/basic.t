#!/usr/bin/perl -w

use warnings;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 20;

BEGIN { use_ok('Ogg::Vorbis::Decoder') }

my $ogg = Ogg::Vorbis::Decoder->open(catdir('data', 'test.ogg'));
ok($ogg, 'open file');

my $buffer;

ok($ogg->sysread($buffer), 'sysread');
ok($ogg->bitrate, 'bitrate');
ok($ogg->bitrate_instant, 'bitrate_instant');
ok($ogg->streams, 'streams');
ok($ogg->seekable, 'seekable');
ok($ogg->serialnumber, 'serialnumber');
is($ogg->raw_total, 4418594, 'raw_total');
ok($ogg->pcm_total, 'pcm_total');
is(sprintf("%.2f", $ogg->time_total), 187.15, 'time_total');
ok($ogg->raw_tell, 'raw_tell');
ok($ogg->pcm_tell, 'pcm_tell');
ok($ogg->time_tell, 'time_tell');
is($ogg->raw_seek(0, 0), 0, 'raw_seek');
is($ogg->pcm_seek(0, 0), 0, 'pcm_seek');
is($ogg->time_seek(0.0), 0, 'time_seek');

undef $ogg;

# test opening from a glob
ok((open FH, catdir('data', 'test.ogg')), 'filehandle');

$ogg = Ogg::Vorbis::Decoder->open(\*FH);

ok($ogg, 'filehandle ogg open');

ok(close(FH), 'close');
