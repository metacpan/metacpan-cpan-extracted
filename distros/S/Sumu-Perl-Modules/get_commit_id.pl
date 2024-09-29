#!/usr/bin/perl

use strict;

print get_commit_id();

sub get_commit_id {
    #return "222";
    my @log = `git log -1`;
    my ($a, $id, $rest) = split(/\s+/, $log[4], 3);
    
    #    022 working on  #2
    #return $log[4];

    $id += 1;

    if ( $id <= 9 ) { $id = "00$id"; }
    elsif ( $id > 9 and $id <= 99 ) { $id = "0$id"; }
    else { $id = $id; }
    #
    return qq{$id}; 
}

1;