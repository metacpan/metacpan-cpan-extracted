#!/usr/bin/perl

use strict;

print get_current_commit_id();

sub get_current_commit_id {
    #
    my @log = `git log -1`;
    my ($a, $id, $rest) = split(/\s+/, $log[4], 3);
    
    #
    #if ( $id <= 9 ) { $id = "00$id"; }
    #elsif ( $id > 9 and $id <= 99 ) { $id = "0$id"; }
    #elsif ( $id > 99 ) { $id = $id; }

    #
    return qq{$id}; 
}