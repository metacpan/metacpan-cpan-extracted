#!/usr/bin/perl

use Net::CDDBSearch;


my $cddb = Net::CDDBSearch->new();


# example 2
# We need to find all albums with names containing 'risk' for example
$cddb->get_albums_album('risk');
$albums = $cddb->albums();

print "You asked : '$cddb->{QUERY}'\n";
print "Founded .....\n";
print $_,"\t ==> ",@{$albums->{$_}}[0],' : ',@{$albums->{$_}}[1], "\n" foreach keys %{$albums};

exit;
