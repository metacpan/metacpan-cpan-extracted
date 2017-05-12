#!/usr/bin/perl

use MusicBrainz::DiscID;
use strict;


my $disc = new MusicBrainz::DiscID();

# read the disc in the default disc drive */
if ( $disc->read() == 0 ) {
    printf STDERR "Error: %s\n", $disc->error_msg();
    exit(1);
}

printf("DiscID        : %s\n", $disc->id());
printf("FreeDB DiscID : %s\n", $disc->freedb_id());

printf("First track   : %d\n", $disc->first_track_num());
printf("Last track    : %d\n", $disc->last_track_num());

printf("Length        : %d sectors\n", $disc->sectors());

for ( my $i = $disc->first_track_num;
    $i <= $disc->last_track_num; $i++ ) {

    printf("Track %-2d      : %8d %8d\n", $i,
        $disc->track_offset($i),
        $disc->track_length($i));
}

printf("Submit via    : %s\n", $disc->submission_url());
printf("WS url        : %s\n", $disc->webservice_url());

undef $disc;
