#!/usr/bin/perl
#

use strict;
use Test::More;

# use a BEGIN block so we print our plan before modules are loaded
BEGIN { plan tests => 56 }

# load modules
use MusicBrainz::DiscID;


# Create a new object
my $disc = new MusicBrainz::DiscID();
ok( $disc );
is(ref $disc, 'MusicBrainz::DiscID');

ok( !$disc->put( 1, 140, 1 .. 100 ) );

like( $disc->error_msg, qr{Illegal (parameters|track limits)} );

ok( $disc->put( 1, 303602,
                150, 9700, 25887, 39297, 53795, 63735, 77517, 94877, 107270,
		            123552, 135522, 148422, 161197, 174790, 192022, 205545,
		            218010, 228700, 239590, 255470, 266932, 288750 )
);

is( $disc->id, 'xUp1F2NkfP8s8jaeFn_Av3jNEI4-');
is( $disc->first_track_num, 1);
is( $disc->freedb_id, '370fce16');
is( $disc->last_track_num, 22);
is( $disc->sectors, 303602);
like( $disc->submission_url, qr{http://(mm\.musicbrainz\.org/bare/cdlookup\.html|musicbrainz\.org/cdtoc/attach)\?id=xUp1F2NkfP8s8jaeFn_Av3jNEI4-&tracks=22&toc=1\+22\+303602\+150\+9700\+25887\+39297\+53795\+63735\+77517\+94877\+107270\+123552\+135522\+148422\+161197\+174790\+192022\+205545\+218010\+228700\+239590\+255470\+266932\+288750});
like( $disc->webservice_url, qr{http://(mm\.)?musicbrainz\.org/ws/1/release\?type=xml&discid=xUp1F2NkfP8s8jaeFn_Av3jNEI4-&toc=1\+22\+303602\+150\+9700\+25887\+39297\+53795\+63735\+77517\+94877\+107270\+123552\+135522\+148422\+161197\+174790\+192022\+205545\+218010\+228700\+239590\+255470\+266932\+288750});

is( $disc->track_offset(1), 150);
is( $disc->track_offset(2), 9700);
is( $disc->track_offset(3), 25887);
is( $disc->track_offset(4), 39297);
is( $disc->track_offset(5), 53795);
is( $disc->track_offset(6), 63735);
is( $disc->track_offset(7), 77517);
is( $disc->track_offset(8), 94877);
is( $disc->track_offset(9), 107270);
is( $disc->track_offset(10), 123552);
is( $disc->track_offset(11), 135522);
is( $disc->track_offset(12), 148422);
is( $disc->track_offset(13), 161197);
is( $disc->track_offset(14), 174790);
is( $disc->track_offset(15), 192022);
is( $disc->track_offset(16), 205545);
is( $disc->track_offset(17), 218010);
is( $disc->track_offset(18), 228700);
is( $disc->track_offset(19), 239590);
is( $disc->track_offset(20), 255470);
is( $disc->track_offset(21), 266932);
is( $disc->track_offset(22), 288750);

is( $disc->track_length(1), 9550);
is( $disc->track_length(2), 16187);
is( $disc->track_length(3), 13410);
is( $disc->track_length(4), 14498);
is( $disc->track_length(5), 9940);
is( $disc->track_length(6), 13782);
is( $disc->track_length(7), 17360);
is( $disc->track_length(8), 12393);
is( $disc->track_length(9), 16282);
is( $disc->track_length(10), 11970);
is( $disc->track_length(11), 12900);
is( $disc->track_length(12), 12775);
is( $disc->track_length(13), 13593);
is( $disc->track_length(14), 17232);
is( $disc->track_length(15), 13523);
is( $disc->track_length(16), 12465);
is( $disc->track_length(17), 10690);
is( $disc->track_length(18), 10890);
is( $disc->track_length(19), 15880);
is( $disc->track_length(20), 11462);
is( $disc->track_length(21), 21818);
is( $disc->track_length(22), 14852);

undef $disc;
